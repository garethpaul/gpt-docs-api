---
title: GPT Docs API Request Query Validation
type: fix
status: completed
date: 2026-06-09
---

# GPT Docs API Request Query Validation

## Summary

Reject malformed query values before `/ask` or `/classify/builder` spend
OpenAI, Pinecone, DynamoDB, or cache work on invalid input.

## Requirements

- R1. Missing and whitespace-only `query` values must return the existing
  missing-query validation error.
- R2. Non-string `query` values must return a clear validation error.
- R3. Valid query strings must be stripped before downstream model and cache
  helpers receive them.
- R4. The source baseline guard must require the new validation tests and
  implementation markers.

## Implementation

- Updated `validate_request_payload` to require a JSON object body and a string
  `query` value.
- Trimmed valid query strings before returning them to route handlers.
- Expanded utility tests for whitespace-only, non-string, and padded valid
  queries.
- Updated `scripts/check-baseline.sh` and `CHANGES.md` to record the contract.

## Verification

- `PYTHONPATH=api python -m unittest api.tests.test_utils`
- `make verify`
- `git diff --check`
