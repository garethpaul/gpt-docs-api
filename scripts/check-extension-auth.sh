#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

for directory in chrome_extension api/chalicelib/public; do
  for file in background.js options.html options.js; do
    if [ ! -f "$ROOT_DIR/$directory/$file" ]; then
      printf '%s\n' "Required extension authentication asset is missing: $directory/$file" >&2
      exit 1
    fi
  done

  node --check "$ROOT_DIR/$directory/content.js"
  node --check "$ROOT_DIR/$directory/background.js"
  node --check "$ROOT_DIR/$directory/options.js"
done

node - "$ROOT_DIR" <<'EOF'
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const root = process.argv[2];
const directories = ["chrome_extension", "api/chalicelib/public"];

function loadHelpers(relativePath, marker, context) {
  const file = path.join(root, relativePath);
  const source = fs.readFileSync(file, "utf8");
  const markerIndex = source.indexOf(marker);
  assert.notEqual(markerIndex, -1, `${relativePath} is missing ${marker}`);
  vm.createContext(context);
  vm.runInContext(source.slice(0, markerIndex), context, { filename: file });
  return source;
}

async function verifyContentScript(directory) {
  const fetchCalls = [];
  let configuration = {
    apiBaseUrl: "https://self-hosted.example/api/",
    apiKey: "user-session-key",
  };
  const context = {
    URL,
    fetch: async (url, options) => {
      fetchCalls.push({ url, options });
      return { ok: true, status: 200, json: async () => ({ ok: true }) };
    },
    chrome: {
      runtime: {
        sendMessage(message, callback) {
          assert.equal(message.type, "getClientConfiguration");
          callback(configuration);
        },
      },
    },
  };
  loadHelpers(
    `${directory}/content.js`,
    "// Create a new <style> element",
    context,
  );

  assert.equal(
    context.normalizeApiBaseUrl("https://self-hosted.example/api/"),
    "https://self-hosted.example/api",
  );
  assert.equal(context.normalizeApiBaseUrl("http://self-hosted.example"), null);
  assert.equal(context.normalizeApiBaseUrl("https://user:pass@self-hosted.example"), null);
  assert.equal(context.normalizeApiBaseUrl("https://self-hosted.example/api?mode=test"), null);
  assert.equal(context.normalizeApiBaseUrl("https://self-hosted.example/api#fragment"), null);

  await context.requestApi("/ask", { query: "How do I send SMS?" });
  await context.requestApi("/classify/builder", { query: "How do I send SMS?" });
  assert.equal(fetchCalls.length, 2);
  assert.deepEqual(fetchCalls.map((call) => call.url), [
    "https://self-hosted.example/api/ask",
    "https://self-hosted.example/api/classify/builder",
  ]);
  for (const call of fetchCalls) {
    assert.equal(call.options.method, "POST");
    assert.equal(call.options.headers["Content-Type"], "application/json");
    assert.equal(call.options.headers["X-GPT-Docs-API-Key"], "user-session-key");
  }

  configuration = { apiBaseUrl: "https://self-hosted.example/api", apiKey: "" };
  await assert.rejects(
    context.requestApi("/ask", { query: "blocked" }),
    /Configure an HTTPS API URL and browser-session API key/,
  );
  assert.equal(fetchCalls.length, 2);
  configuration = { apiBaseUrl: "http://insecure.example", apiKey: "key" };
  await assert.rejects(
    context.requestApi("/ask", { query: "blocked" }),
    /Configure an HTTPS API URL and browser-session API key/,
  );
  assert.equal(fetchCalls.length, 2);
  await assert.rejects(
    context.requestApi("/arbitrary", { query: "blocked" }),
    /Unsupported API route/,
  );
  assert.equal(fetchCalls.length, 2);
}

function verifyBackground(directory) {
  let listener;
  const context = {
    chrome: {
      runtime: {
        id: "extension",
        onMessage: {
          addListener(callback) {
            listener = callback;
          },
        },
      },
      storage: {
        local: {
          get(keys, callback) {
            assert.equal(JSON.stringify(keys), '["gptDocsApiBaseUrl"]');
            callback({ gptDocsApiBaseUrl: "https://self-hosted.example/api" });
          },
        },
        session: {
          get(keys, callback) {
            assert.equal(JSON.stringify(keys), '["gptDocsApiKey"]');
            callback({ gptDocsApiKey: "user-session-key" });
          },
        },
      },
    },
  };
  const source = fs.readFileSync(path.join(root, directory, "background.js"), "utf8");
  vm.createContext(context);
  vm.runInContext(source, context, { filename: `${directory}/background.js` });
  assert.equal(typeof listener, "function");
  assert.equal(
    listener(
      { type: "getClientConfiguration" },
      { id: "different-extension" },
      () => { throw new Error("foreign senders must not receive configuration"); },
    ),
    false,
  );
  let response;
  const asynchronous = listener(
    { type: "getClientConfiguration" },
    { id: "extension" },
    (value) => { response = value; },
  );
  assert.equal(asynchronous, true);
  assert.equal(response.apiBaseUrl, "https://self-hosted.example/api");
  assert.equal(response.apiKey, "user-session-key");
}

async function verifyOptions(directory) {
  const writes = [];
  const context = { URL };
  loadHelpers(`${directory}/options.js`, "// Wire options page", context);
  const storage = {
    local: {
      async set(value) { writes.push(["local", value]); },
    },
    session: {
      async set(value) { writes.push(["session", value]); },
    },
    sync: {
      async set() { throw new Error("API keys must not use sync storage"); },
    },
  };
  await context.saveClientConfiguration(
    storage,
    "https://self-hosted.example/api/",
    "user-session-key",
  );
  assert.equal(JSON.stringify(writes), JSON.stringify([
    ["local", { gptDocsApiBaseUrl: "https://self-hosted.example/api" }],
    ["session", { gptDocsApiKey: "user-session-key" }],
  ]));
  await assert.rejects(
    context.saveClientConfiguration(storage, "http://insecure.example", "key"),
    /HTTPS API URL/,
  );
  await assert.rejects(
    context.saveClientConfiguration(
      storage,
      "https://user:pass@self-hosted.example",
      "key",
    ),
    /HTTPS API URL/,
  );
}

(async () => {
  for (const directory of directories) {
    const manifest = JSON.parse(
      fs.readFileSync(path.join(root, directory, "manifest.json"), "utf8"),
    );
    assert.equal(manifest.manifest_version, 3);
    assert.equal(manifest.minimum_chrome_version, "102");
    assert.ok(manifest.permissions.includes("storage"));
    assert.equal(manifest.options_page, "options.html");
    assert.equal(manifest.background.service_worker, "background.js");
    await verifyContentScript(directory);
    verifyBackground(directory);
    await verifyOptions(directory);
  }

  for (const file of ["background.js", "options.html", "options.js"]) {
    assert.equal(
      fs.readFileSync(path.join(root, directories[0], file), "utf8"),
      fs.readFileSync(path.join(root, directories[1], file), "utf8"),
      `${file} must stay mirrored`,
    );
  }
  console.log("GPT Docs extension authentication checks passed.");
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
EOF
