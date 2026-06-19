---
title: Retrieval Response Accessor Safety
date: 2026-06-16
status: completed
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

## Work Completed

- Verified mapping accessors are callable before invocation and otherwise used
  safe object attribute lookup.
- Normalized mapping and attribute accessor exceptions to no retrieval matches.
- Preserved mapping/object list and tuple compatibility and query-only answer
  generation.
- Added focused runtime regressions, mutation-sensitive static contracts, and
  project guidance for the accessor boundary.

## Verification Completed

- Focused accessor tests and the complete API suite passed with 50 tests.
- All four Make gates passed: `make check`, `make lint`, `make test`, and
  `make build`.
- The external-directory Make gate passed through the absolute Makefile path.
- Six isolated mutations were rejected: unconditional mapping access, propagated
  accessor exceptions, discarded safe attributes, removed focused tests,
  reopened plan status, and removed verification evidence.
- Compound Engineering review found no actionable findings or testing gaps;
  browser validation was not applicable to this backend-only change.
- Dependency lock, binary package policy, extension rendering, Python compile,
  diff, explicit artifact cleanup, credential, conflict-marker, file-mode, and
  upstream audits passed.
- Both canonical implementation-head checks passed at
  `ad593c9194285ea4a839ca046b31c1dc91427948`: push run 27646936359 and
  pull-request run 27646948344. PR #31 was OPEN and MERGEABLE with all six
  required body sections, and code-scanning, Dependabot, and secret-scanning
  queries returned zero open alerts.
- No live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, or deployment
  operation was executed.
