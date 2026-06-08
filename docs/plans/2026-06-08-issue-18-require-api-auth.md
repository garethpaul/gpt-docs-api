# Issue 18: require inbound API authentication

## Context

Issue #18 reports that public POST routes accept caller JSON and spend server-side OpenAI/Pinecone credentials without authenticating the caller first.

## Plan

1. Add a dedicated `GPT_DOCS_API_KEY` configuration value for inbound API callers.
2. Require `Authorization: Bearer <key>` or `X-API-Key: <key>` on model-backed POST routes before reading request JSON or calling cache/model helpers.
3. Return deterministic unauthorized responses for missing or incorrect credentials.
4. Add route-level tests proving unauthenticated requests do not call cache, Pinecone, OpenAI, or classification helpers.

## Verification

- `PYTHONPATH=api python3 -m unittest api.tests.test_app_auth`
- `make verify`
- `git diff --check`
