---
title: GPT Docs API Testability and Dependency Baseline
type: chore
status: active
date: 2026-06-08
---

# GPT Docs API Testability and Dependency Baseline

## Summary

Raise the engineering bar for the Chalice-based GPT Docs API by removing import-time cloud side effects, adding deterministic unit tests for request validation, cache access, OpenAI adapters, and JSON parsing, and refreshing dependency pins within compatibility-safe bounds.

## Problem Frame

The API currently has no automated test suite, imports AWS DynamoDB resources at module import time, and has request-validation helpers that depend on Chalice even when only pure parsing logic is needed. The runtime dependency pins are also stale: OpenAI is pinned to `0.27.0`, Pinecone to `2.2.1`, and boto3 to `1.18.49`, while current registry metadata on 2026-06-08 reports OpenAI `2.38.0`, Pinecone client `6.0.0`, boto3 `1.43.18`, and Chalice `1.33.0`. The OpenAI and Pinecone latest majors require API rewrites, so this pass creates the test harness and does a conservative refresh before a larger client migration.

## Requirements

- R1. Unit tests must run without AWS credentials, AWS region configuration, OpenAI credentials, Pinecone credentials, or network access.
- R2. Importing `chalicelib.cache`, `chalicelib.utils`, and `chalicelib.classification` must not create cloud resources or require Chalice-only imports.
- R3. Cache reads and writes must preserve the existing DynamoDB key and item shapes while allowing fake table injection in tests.
- R4. Request payload validation must preserve the current error messages for missing JSON bodies and missing `query` values.
- R5. JSON extraction must return parsed objects from model text that contains surrounding prose and return `{}` for malformed or missing JSON without printing to stdout.
- R6. OpenAI adapter functions must preserve the legacy `openai.Embedding.create` and `openai.ChatCompletion.create` call shapes while allowing fake client injection in tests.
- R7. The repository must expose repeatable local quality gates for tests and syntax compilation.
- R8. Dependency pins must be refreshed where compatible without silently attempting the OpenAI 2.x or Pinecone 6.x migration in this pass.
- R9. Documentation must describe setup, required environment variables, test commands, and deferred dependency modernization risks.

## Key Technical Decisions

- **Use stdlib unittest:** Avoid adding a test dependency while creating a reliable baseline that works in the current Python 3.12 host.
- **Lazy DynamoDB table creation:** Replace import-time `boto3.resource("dynamodb")` with a helper that creates the table only when cache access is actually requested.
- **Inject external clients:** Let cache and OpenAI functions accept optional fake collaborators so tests can assert behavior without network calls.
- **Keep legacy OpenAI/Pinecone APIs for this pass:** Move OpenAI from `0.27.0` to the final legacy-compatible `0.28.1` and Pinecone from `2.2.1` to `2.2.4`, then defer latest-major migrations to a follow-up with route-level tests.
- **Add Chalice explicitly:** The app imports `chalice` but `api/requirements.txt` does not list it; adding `chalice==1.33.0` makes local setup and deployment intent explicit.

## Scope Boundaries

- This pass does not migrate to the OpenAI 2.x client API.
- This pass does not migrate to the Pinecone 6.x client API.
- This pass does not delete or regenerate the checked-in `api/vendor` directory.
- This pass does not add live integration tests against OpenAI, Pinecone, DynamoDB, or Twilio documentation.
- This pass does not change public Chalice route paths or response body shapes.

## Implementation Units

### U1. Import-Safe Cache Boundary

- **Goal:** Make cache helpers testable without AWS region configuration or credentials.
- **Files:** `api/chalicelib/cache.py`, `api/tests/test_cache.py`
- **Patterns:** Add `get_cache_table(resource=None)` and optional `table` parameters to `get_cached_response` and `store_in_cache`.
- **Test Scenarios:**
  - Importing `chalicelib.cache` does not create a DynamoDB resource.
  - `get_cached_response("hello", table=fake)` calls `fake.get_item(Key={"query_string": "hello"})` and returns the `Item`.
  - Missing `Item` returns `None`.
  - `store_in_cache("hello", "answer", ["url"], table=fake)` writes the existing item shape.
- **Verification:** `make test`

### U2. Pure Request and JSON Utility Tests

- **Goal:** Remove the Chalice import from pure utility code and lock down parsing behavior.
- **Files:** `api/chalicelib/utils.py`, `api/tests/test_utils.py`
- **Patterns:** Use `ValueError` for helper-level validation errors; app routes can still translate validation failures into HTTP responses.
- **Test Scenarios:**
  - `validate_request_payload(None)` raises `ValueError("Request body must be JSON")`.
  - `validate_request_payload({})` raises `ValueError("Request body must be JSON")`.
  - `validate_request_payload({"query": ""})` raises `ValueError('Missing "query" key in request body')`.
  - `validate_request_payload({"query": "How?"})` returns `"How?"`.
  - `extract_json_object("prefix {\"with_code\": 0.7} suffix")` returns the parsed object.
  - malformed text and text without braces return `{}` without stdout output.
- **Verification:** `make test`

### U3. OpenAI Adapter Injection Tests

- **Goal:** Cover embedding, response generation, and classification behavior without OpenAI credentials or network calls.
- **Files:** `api/chalicelib/classification.py`, `api/tests/test_classification.py`
- **Patterns:** Add optional `openai_client` parameters that default to the imported legacy OpenAI module.
- **Test Scenarios:**
  - `get_embeddings("query", openai_client=fake)` sets the API key and returns the first embedding vector.
  - `generate_response("query", openai_client=fake)` sends the configured system primer and user query, then returns message content.
  - `generate_classification("model", "query", openai_client=fake)` parses JSON classification content.
  - OpenAI errors are wrapped in a clear `Failed to generate classification` exception.
- **Verification:** `make test`

### U4. Local Quality Gates and Conservative Dependency Refresh

- **Goal:** Give future modernization work a repeatable baseline and update compatible pins.
- **Files:** `Makefile`, `api/requirements.txt`, `README.md`
- **Patterns:** Keep commands shell-simple and repo-root oriented; compile only source and tests, not vendored dependencies.
- **Test Scenarios:**
  - `make test` runs `PYTHONPATH=api python -m unittest discover -s api/tests`.
  - `make compile` runs syntax compilation over `api/app.py`, `api/chalicelib`, and `api/tests`.
  - `make verify` runs both gates.
  - `api/requirements.txt` includes `chalice==1.33.0`, `openai==0.28.1`, `pinecone-client[grpc]==2.2.4`, and `boto3==1.43.18`.
  - README documents the commands and the deferred OpenAI/Pinecone latest-major migration.
- **Verification:** `make verify`

## Risks & Dependencies

- OpenAI 2.x and Pinecone 6.x are current but require code changes beyond a pin update; attempting that before adding tests would make regressions hard to identify.
- The checked-in `api/vendor` directory contains compiled binary artifacts for older Python ABIs. This pass avoids changing it, but a future deployment cleanup should decide whether vendor contents are still needed.
- Chalice itself is not installed in the current host environment, so this pass focuses tests on import-safe helpers and syntax compilation rather than running a local Chalice server.

## Sources / Research

- `api/app.py` contains the Chalice routes and imports cache, classification, and configuration modules.
- `api/chalicelib/cache.py` creates the DynamoDB resource at import time and currently fails without AWS region configuration.
- `api/chalicelib/utils.py` imports Chalice for validation helper exceptions.
- `api/chalicelib/classification.py` uses legacy OpenAI global APIs.
- `api/requirements.txt` currently pins `openai==0.27.0`, `pinecone-client[grpc]==2.2.1`, and `boto3==1.18.49`.
- `python -m pip index versions openai` on 2026-06-08 reported latest OpenAI `2.38.0`.
- `python -m pip index versions pinecone-client` on 2026-06-08 reported latest Pinecone client `6.0.0`.
- `python -m pip index versions boto3` on 2026-06-08 reported latest boto3 `1.43.18`.
- `python -m pip index versions chalice` on 2026-06-08 reported latest Chalice `1.33.0`.
