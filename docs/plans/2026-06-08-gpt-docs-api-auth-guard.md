---
title: GPT Docs API Auth Guard
type: fix
status: completed
date: 2026-06-08
---

# GPT Docs API Auth Guard

## Summary

Close the public AI-spending route gap by requiring caller authentication before
the Chalice API reads request bodies or invokes OpenAI, Pinecone, or DynamoDB
helpers.

## Requirements

- R1. `/ask` and `/classify/builder` must fail closed when `GPT_DOCS_API_KEY`
  is not configured.
- R2. The same routes must reject missing or invalid caller credentials before
  reading JSON request bodies.
- R3. Authorized callers may use either `X-GPT-Docs-API-Key` or
  `Authorization: Bearer <token>`.
- R4. Public static asset serving must remain unauthenticated.
- R5. Tests must prove unauthenticated requests do not call model or retrieval
  helpers.
- R6. Documentation and the source baseline guard must record the auth
  requirement.

## Implementation

- Added `chalicelib.auth` with a pure shared-key guard and explicit
  configuration/authentication exceptions.
- Wired the guard into `/ask` and `/classify/builder` before request body
  parsing.
- Added fake-Chalice route tests that verify unauthenticated requests return
  401 or 503 and do not call AI helpers.
- Added unit coverage for accepted `X-GPT-Docs-API-Key` and bearer-token
  credentials.
- Updated CORS headers to include the auth headers while disabling credentialed
  wildcard CORS.

## Verification

- `make verify`
- `git diff --check`
