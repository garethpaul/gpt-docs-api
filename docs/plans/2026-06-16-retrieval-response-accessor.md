---
title: Retrieval Response Accessor Safety
date: 2026-06-16
status: planned
execution: code
---

## Context

`retrieval_matches()` normalizes malformed `matches` containers, but it first
uses `hasattr(response, 'get')` and then calls `response.get(...)`
unconditionally. A provider wrapper with a non-callable `get` attribute, or an
accessor that raises, fails before the container guard and turns the intended
query-only fallback into an API error.

## Priority

This is the remaining deterministic boundary immediately before the completed
matches-container validation. The response is controlled by an external SDK,
and the behavior can be proved offline without credentials or live services.

## Plan

1. Extract `matches` only through a callable mapping accessor or safe attribute
   lookup.
2. Normalize accessor failures and unsupported response shapes to no matches.
3. Preserve mapping/object list and tuple compatibility, context budgets,
   citation filtering, and query-only generation.
4. Add focused runtime tests and mutation-sensitive baseline contracts.
5. Record actual focused, full-gate, external-directory, review, audit, and
   hosted verification evidence.

## Verification

- Run focused API tests and the complete `make check`, `make lint`, `make test`,
  and `make build` gates with explicit timeouts.
- Run the absolute-Makefile check from an external directory.
- Reject mutations that restore unconditional `.get`, propagate accessor
  failures, remove focused tests, or reopen completed plan evidence.
- Audit exact diff, dependency lock/package output, explicit generated
  artifacts, credential-like additions, file modes, and upstream state.

## Boundaries

- No live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, or deployment
  operation is required or claimed.
- Query-only generation after malformed retrieval remains existing behavior.
