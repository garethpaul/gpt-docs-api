---
title: Retrieval Matches Container
date: 2026-06-16
status: completed
execution: code
---

## Context

`make_query` validates every Pinecone match's metadata, but it iterates the
top-level `matches` value without checking the container shape. A provider
response containing `matches: null`, a scalar, or a mapping raises before the
existing metadata guard can skip malformed items.

## Priority

This is the highest-value remaining deterministic response-shape gap because it
is controlled by an external retrieval provider, bypasses the established
per-item resilience boundary, and can be covered without credentials or live
OpenAI, Pinecone, DynamoDB, or AWS calls.

## Plan

1. Add a small helper that returns only list or tuple match collections and
   normalizes every other shape to an empty collection.
2. Route `make_query` through the helper before per-item metadata validation.
3. Add focused tests for valid mapping/object responses and malformed matches
   container values while preserving the query-only generated prompt.
4. Extend the baseline, guidance, changelog, and completed-plan contract.
5. Run focused and full tests, all Make gates, external-directory validation,
   isolated mutations, and final artifact/secret/diff audits.
6. Push the exact branch, open a stacked pull request against the binary-only
   dependency branch, and take one bounded hosted/security snapshot.

## Non-Goals

- Calling live Pinecone or OpenAI services.
- Changing per-match metadata, URL filtering, or context-length behavior.
- Changing dependency locks, binary-only policy, or deployment packaging.
- Migrating legacy OpenAI or Pinecone client APIs.

## Verification Required

- Focused retrieval tests and the complete API test suite pass.
- `make check`, `make lint`, `make test`, and `make build` pass from the
  repository, and the absolute Makefile check passes externally.
- Mutations removing the container guard, accepting mappings as iterable
  matches, removing focused coverage, or staling plan evidence fail.
- Final intended paths pass compile, whitespace, artifact, credential,
  conflict-marker, file-mode, lock-consistency, and upstream-alignment audits.

## Work Completed

- Added `retrieval_matches` to accept list and tuple collections while
  normalizing malformed top-level provider values to an empty tuple.
- Routed `make_query` through the helper and added malformed-container
  characterization, static, guidance, and completed-plan contracts.

## Verification Completed

- The focused retrieval tests and complete API suite passed with 48 tests.
- All four Make gates passed in the isolated baseline mirror and final worktree.
- The external-directory Make gate passed through the absolute Makefile path.
- The container-guard mutation failed after removing the shape check.
- The mapping-acceptance mutation failed after treating mappings as match
  collections.
- The focused-test contract mutation failed after renaming the malformed
  matches characterization.
- The plan-status mutation failed after restoring an active status.
- The plan-evidence mutation failed after removing the guard-mutation result.
- Compile, dependency-lock, extension-rendering, diff, generated-artifact,
  credential, conflict-marker, file-mode, and upstream audits completed before
  commit.
