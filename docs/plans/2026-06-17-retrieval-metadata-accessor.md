---
title: Retrieval Metadata Accessor Safety
date: 2026-06-17
status: completed
execution: code
---

## Context

Top-level Pinecone response access is normalized before match iteration, but
`metadata_text_and_url` still invokes a match mapping's `get` method or reads
its `metadata` attribute without containing provider accessor failures. A
single malformed match can therefore abort an authenticated `/ask` request
instead of being skipped like other unusable retrieval metadata.

## Priority

This is the highest-value remaining deterministic retrieval boundary because
the value is controlled by an external provider, bypasses the existing
per-match shape guard, and can be fixed and verified without credentials or
live OpenAI, Pinecone, DynamoDB, AWS, Twilio, or deployment calls.

## Plan

1. Add a small metadata accessor helper that calls only callable mapping
   accessors, preserves safe object attribute fallback, and normalizes accessor
   exceptions to missing metadata.
2. Keep the existing dictionary, text, URL, and context-budget validation
   unchanged after metadata access succeeds.
3. Add focused runtime regressions and mutation-sensitive static contracts for
   non-callable, raising mapping, and raising attribute accessors.
4. Update repository guidance and the changelog for the provider boundary.
5. Run focused and complete tests, all Make gates, the external-directory gate,
   isolated mutations, structured review, and final artifact/secret/diff
   audits.
6. Push the exact branch, open a stacked pull request against the retrieval
   response accessor branch, and take one bounded hosted/security snapshot.

## Non-Goals

- Calling live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, or
  deployment services.
- Changing top-level matches-container or response-accessor behavior.
- Changing accepted metadata, URL filtering, prompt budgets, cache behavior,
  dependency locks, binary-package policy, or deployment packaging.
- Migrating legacy OpenAI or Pinecone client APIs.

## Verification Required

- Focused metadata accessor tests and the complete API suite pass.
- `make check`, `make lint`, `make test`, and `make build` pass from the
  repository, and the absolute Makefile check passes externally.
- Mutations restoring unconditional mapping access, propagating accessor
  failures, accepting non-callable accessors, removing focused coverage, or
  staling plan evidence fail.
- Compound Engineering review has no unresolved actionable findings.
- Final intended paths pass compile, dependency-lock, extension-rendering,
  whitespace, artifact, credential, conflict-marker, file-mode, and
  upstream-alignment audits.

## Work Completed

- Added `retrieval_metadata` to verify dictionary accessors before invocation,
  normalize accessor exceptions to missing metadata, and preserve object-style
  metadata attributes.
- Kept the existing metadata shape, text, URL, context, and citation policies
  unchanged after successful access.
- Added focused helper and mixed-match request regressions, mutation-sensitive
  baseline contracts, and repository guidance for the provider boundary.

## Verification Completed

- Focused metadata accessor regressions and the complete API suite passed with
  52 tests.
- All four Make gates passed: `make check`, `make lint`, `make test`, and
  `make build`.
- The external-directory Make gate passed through the absolute Makefile path.
- Six isolated mutations were rejected: unconditional mapping access, narrowed
  exception containment, non-callable invocation, object dispatch regression,
  focused-test removal, and guidance removal.
- Compound Engineering review resolved one object-compatibility finding and
  ended with no actionable findings.
- Dependency lock, extension rendering, Python compilation, diff, explicit
  artifact cleanup, credential-pattern, conflict-marker, file-mode,
  clean-worktree, and exact-upstream audits passed.
- Both canonical implementation-head checks passed at
  `fa00a133c7149d6e3b80bb93a64fe5638bfaef14`: push run 27664285855 and
  pull-request run 27664290314. PR #32 was OPEN, CLEAN, and MERGEABLE, and
  code-scanning, Dependabot, and secret-scanning queries returned zero open
  alerts.
- No live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, or deployment
  operation was executed.
