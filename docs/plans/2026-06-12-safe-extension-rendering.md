---
title: Safe Extension Rendering
type: fix
status: completed
date: 2026-06-12
origin: issue 16 and pull request 17
execution: code
---

# Safe Extension Rendering

## Context

Both shipped copies of the GPT Docs content script assign user queries, model
responses, and source links through `innerHTML`. The script runs inside Twilio
documentation pages, so remote or user-controlled strings can be interpreted
as host-page markup instead of displayed as text. Source links are also opened
with `_blank` without opener isolation or protocol validation.

Pull request 17 proposed the core text-rendering fix, but it predates the
current API baseline and does not connect its regression guard to `make check`.
The two bundles now also intentionally differ in their icon asset and API
endpoint, which this change must preserve.

## Priority

Issue 16 is labeled P1 and URGENT because the vulnerable sinks cross a browser
extension trust boundary and can modify a third-party documentation page.

## Prioritized Engineering Backlog

1. Remove scriptable HTML sinks from both content-script bundles now.
2. Add browser-level extension integration tests when the project gains a
   maintained extension test harness.
3. Consolidate the duplicated content script through a build step only if the
   repository adopts a JavaScript toolchain.

## Requirements

- R1. User query text, model response text, loader text, labels, and static UI
  text must be assigned through text-only DOM APIs.
- R2. Source links must be parsed and restricted to `http:` or `https:` before
  an `href` is assigned.
- R3. External source links opened with `_blank` must use
  `rel="noopener noreferrer"`.
- R4. The navigation item must be built with DOM APIs rather than an HTML
  string.
- R5. Both `chrome_extension/content.js` and
  `api/chalicelib/public/content.js` must receive the same security behavior
  while retaining their existing icon and endpoint differences.
- R6. The canonical `make check` gate must run syntax and static security
  regressions for both content-script copies.
- R7. Existing API behavior and the dependency-free Python test suite must
  remain unchanged.

## Implementation Units

### U1. Replace HTML rendering sinks

- **Files:** `chrome_extension/content.js`,
  `api/chalicelib/public/content.js`
- Add shared text and URL helpers within each bundle, replace `innerHTML`
  assignments, validate source URLs, isolate external links, and construct the
  nav item through element APIs.

### U2. Enforce the browser security contract

- **Files:** `scripts/check-extension-rendering.sh`,
  `scripts/check-baseline.sh`
- Reject HTML sinks and missing URL/opener protections, syntax-check both
  bundles with Node, and run the guard from the canonical baseline.

### U3. Record the public behavior

- **Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`
- Document text-only remote rendering, HTTP(S)-only source links, and the
  extension verification gate.

## Scope Boundaries

- Do not change API endpoints, icon assets, analytics, authentication, or
  response schemas.
- Do not add a JavaScript package manager or runtime dependency.
- Do not intentionally preserve HTML formatting returned by the model.

## Verification

- `scripts/check-extension-rendering.sh`
- `node --check chrome_extension/content.js`
- `node --check api/chalicelib/public/content.js`
- `make verify`
- `git diff --check`
- Mutations restoring response `innerHTML`, unsafe URL assignment, or missing
  opener isolation must fail the regression guard.

Completed on 2026-06-12 with both content-script copies syntax-checked, the
text and URL helper behavior exercised, all 41 API tests passing, the canonical
baseline green, and hostile rendering mutations rejected.
