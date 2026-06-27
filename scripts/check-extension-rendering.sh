#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
set -- \
  "$ROOT_DIR/chrome_extension/content.js" \
  "$ROOT_DIR/api/chalicelib/public/content.js"

for file in "$@"; do
  if grep -Fq 'innerHTML' "$file"; then
    printf '%s\n' "$file must not render content with innerHTML." >&2
    exit 1
  fi

  for contract in \
    'function setText(element, value)' \
    'function safeHttpUrl(value)' \
    'parsed.protocol === "https:" || parsed.protocol === "http:"' \
    'newAnchor.setAttribute("href", safeUrl)' \
    'newAnchor.setAttribute("rel", "noopener noreferrer")' \
    'setText(h2, inputText)' \
    'setText(p, text)' \
    'newListItem.appendChild(navLink)'; do
    if ! grep -Fq "$contract" "$file"; then
      printf '%s\n' "$file is missing extension rendering contract: $contract" >&2
      exit 1
    fi
  done

  node --check "$file"
  node - "$file" <<'EOF'
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

const file = process.argv[2];
const source = fs.readFileSync(file, "utf8");
const marker = "// Create a new <style> element";
const markerIndex = source.indexOf(marker);
assert.notEqual(markerIndex, -1, `${file} is missing the helper boundary`);

const context = { URL };
vm.createContext(context);
vm.runInContext(source.slice(0, markerIndex), context, { filename: file });

const element = {};
context.setText(element, '<img src=x onerror="alert(1)">');
assert.equal(element.textContent, '<img src=x onerror="alert(1)">');
assert.equal(context.safeHttpUrl("javascript:alert(1)"), null);
assert.equal(context.safeHttpUrl("data:text/html,unsafe"), null);
assert.equal(context.safeHttpUrl("https://www.twilio.com/docs"), "https://www.twilio.com/docs");
assert.equal(context.safeHttpUrl("http://example.test/path"), "http://example.test/path");
EOF
done

printf '%s\n' "GPT Docs extension rendering checks passed."
