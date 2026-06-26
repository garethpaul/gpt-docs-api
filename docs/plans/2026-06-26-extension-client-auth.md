# Extension Client Authentication Implementation Plan

status: completed

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Make both bundled extension clients compatible with authenticated self-hosted API deployments without shipping a shared server secret.

**Architecture:** Store the user-selected HTTPS API base URL in extension-local storage and the user-supplied API key in browser-session storage. A background worker exposes configuration through extension messaging, while mirrored content scripts add the fixed API-key header to the two supported routes and refuse network calls when configuration is unavailable.

**Tech Stack:** Manifest V3, vanilla JavaScript, Chrome Storage and Runtime APIs, Node VM contract tests, shell/Python baseline gates.

---

### Task 1: Add failing client-auth contracts

**Files:**
- Create: `scripts/check-extension-auth.sh`
- Modify: `Makefile`

**Step 1: Write the failing test**

Create a Node VM harness that loads each content script with mocked
`chrome.runtime.sendMessage` and `fetch`. Require `/ask` and
`/classify/builder` requests to use the configured HTTPS base URL and
`X-GPT-Docs-API-Key`, and require missing configuration to perform zero fetches.

**Step 2: Run test to verify it fails**

Run: `./scripts/check-extension-auth.sh`

Expected: FAIL because no configuration messaging or API-key header exists.

### Task 2: Add extension configuration assets

**Files:**
- Create: `chrome_extension/background.js`
- Create: `chrome_extension/options.html`
- Create: `chrome_extension/options.js`
- Create: `api/chalicelib/public/background.js`
- Create: `api/chalicelib/public/options.html`
- Create: `api/chalicelib/public/options.js`
- Modify: `chrome_extension/manifest.json`
- Modify: `api/chalicelib/public/manifest.json`

**Step 1: Write failing storage contracts**

Extend the auth harness to require HTTPS endpoint validation, local endpoint
storage, session-only key storage, mirrored files, and Manifest V3 declarations
for `storage`, `options_page`, and the background service worker.

**Step 2: Run test to verify it fails**

Run: `./scripts/check-extension-auth.sh`

Expected: FAIL because the assets and manifest declarations are absent.

**Step 3: Write minimal implementation**

Implement options save/restore and a message handler that returns the local
endpoint plus session key. Do not persist the key to local or sync storage.

**Step 4: Run test to verify it passes**

Run: `./scripts/check-extension-auth.sh`

Expected: PASS for configuration storage and messaging contracts.

### Task 3: Authenticate both API flows

**Files:**
- Modify: `chrome_extension/content.js`
- Modify: `api/chalicelib/public/content.js`
- Modify: `scripts/check-extension-auth.sh`

**Step 1: Run the existing failing route contracts**

Run: `./scripts/check-extension-auth.sh`

Expected: FAIL because both requests still omit the configured credentials.

**Step 2: Write minimal implementation**

Add one configuration loader and one fixed-route request helper. Route both
classification and answer requests through it, require HTTPS configuration,
and return a deterministic setup error without calling `fetch` when absent.

**Step 3: Run test to verify it passes**

Run: `./scripts/check-extension-auth.sh`

Expected: PASS for both routes and both mirrored clients.

### Task 4: Preserve repository policy and guidance

**Files:**
- Modify: `scripts/check-baseline.sh`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `SECURITY.md`
- Modify: `VISION.md`
- Modify: `CHANGES.md`
- Modify: `docs/plans/2026-06-26-extension-client-auth.md`

**Step 1: Add failing baseline contracts**

Require the completed plan, mirrored extension assets, session-only key
guidance, and both route/header contracts.

**Step 2: Run test to verify it fails**

Run: `make check`

Expected: FAIL until guidance and plan evidence are complete.

**Step 3: Update documentation and evidence**

Document the self-hosted trust model, browser-session key lifetime, HTTPS/CORS
requirement, validation commands, findings, blockers, and next action.

**Step 4: Run focused and full validation**

Run: `make verify`

Expected: all Python, JavaScript, extension, syntax, and baseline checks pass
without live credentials.

### Task 5: Review and ship exact head

**Files:**
- Modify only files required by verified review findings.

**Step 1: Run hostile mutations and leak checks**

Mutate each credential route, storage boundary, manifest declaration, mirror
contract, and guidance requirement independently; confirm the gates reject
each mutation. Run `gitleaks detect --no-git --source .` and
`git diff --check`.

**Step 2: Commit and open the pull request**

Commit the focused change, push the branch, and open a PR linked to issue 36.

**Step 3: Run Codex review and hosted checks**

Run the branch review helper, skipping only authentication-only tool failure.
Require Check and CodeQL on the exact PR head.

**Step 4: Merge exact head**

Merge only with `--match-head-commit` after all required checks are green, then
verify issue 36 closes and `main` remains healthy.

## Verification Completed

- The red-first Node contract failed before configuration assets and request
  helpers existed; both authenticated extension routes passed after the minimal
  implementation.
- The red-first Python route contract failed because `/classify/builder` lacked
  CORS and passed after it shared the authenticated `/ask` configuration.
- The complete API suite passed with 65 tests.
- All four Make gates passed with the maintained Python 3.10 dependency
  environment, and `make verify` passed.
- The external-directory Make gate passed using the repository Makefile.
- Thirteen hostile extension authentication mutations were rejected across
  routes, headers, URL validation, configuration messaging, sender ownership,
  session storage, manifests, mirrored assets, and CORS.
- Extension rendering, JavaScript syntax, Python syntax, dependency-lock,
  whitespace, current-tree leak checks, and the 6,313-entry Chalice package
  check passed.
- No live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, browser publication, or deployment operation was executed.
- Codex review and hosted Check/CodeQL remain the merge gates for the exact PR
  head.
