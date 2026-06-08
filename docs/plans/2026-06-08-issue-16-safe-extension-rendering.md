---
title: Issue 16 Safe Extension Rendering
type: fix
status: active
date: 2026-06-08
origin: public repository security audit
execution: code
---

# Issue 16 Safe Extension Rendering

## Summary

Render GPT Docs extension responses as text instead of HTML so model output, query text, and source links cannot inject markup into Twilio documentation pages.

## Problem Frame

The content script writes the user's query, API response text, and source links using `innerHTML`. The response body is generated from remote service output, and the content script runs on Twilio documentation pages, so treating those values as HTML creates a page-injection risk.

## Requirements

- R1. `chrome_extension/content.js` must not use `innerHTML`.
- R2. `api/chalicelib/public/content.js` must not use `innerHTML`.
- R3. User query text, model response text, feedback labels, loader text, and link labels must render with text APIs.
- R4. Source links must be assigned only after URL parsing and must reject non-HTTP(S) protocols.
- R5. External links opened with `_blank` must use `rel="noopener noreferrer"`.
- R6. The GitHub issue and PR must be marked `URGENT`.

## Implementation Unit

### U1. Text-Only Content Script Rendering

- **Goal:** Add `setText` and `safeHttpUrl` helpers to both content-script copies, replace HTML sinks with text rendering, and build the nav item via DOM APIs.
- **Files:** `chrome_extension/content.js`, `api/chalicelib/public/content.js`, `scripts/check-extension-rendering.sh`
- **Verification:** `scripts/check-extension-rendering.sh`, `node --check chrome_extension/content.js`, `node --check api/chalicelib/public/content.js`, and `git diff --check`.

## Risks

- If callers intentionally returned HTML in answers, that formatting will now display as text. This is the safer behavior for untrusted model/API output in a browser extension.
