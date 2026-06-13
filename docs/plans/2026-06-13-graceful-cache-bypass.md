# Graceful Cache Bypass

status: completed

## Context

Every authenticated `/ask` request reads DynamoDB before retrieval and writes
the generated answer afterward. A transient cache read currently prevents the
API from doing useful model work, while a transient cache write discards an
otherwise successful response after OpenAI and Pinecone work has completed.
The cache is an optimization, so its availability should not become the
availability boundary for fresh answers.

## Priority

This is the highest-value remaining isolated route reliability gap. It avoids
unnecessary 500 responses and repeated paid work without changing request
authentication, cache identity, TTL behavior, payload validation, retrieval,
or response shape.

## Scope

1. Treat a cache read exception as a miss and continue to fresh retrieval.
2. Log a cache write exception and still return the generated response.
3. Keep malformed or expired cache entries governed by the existing cache
   helper validation.
4. Add focused route regressions and mutation-sensitive static contracts.

## Verification Plan

- Run focused route tests, all API tests, every Make gate, Python compilation,
  dependency consistency, shell syntax, `git diff --check`, and intended-file
  artifact and secret scans.
- Remove read bypass, remove write isolation, and remove each focused regression;
  every hostile mutation must fail.
- Push a stacked pull request and take one bounded exact-head workflow and
  code-scanning snapshot without polling.

## Risk And Rollback

Cache hits, valid writes, cache keys, TTLs, and response bodies remain
unchanged. During a DynamoDB outage, requests can perform fresh paid model work
instead of failing fast, so operators should monitor cache errors and upstream
usage. Rollback restores cache failures as route-level 500 responses; no data
migration exists.

## Work Completed

- Isolated the response-cache read so backend exceptions are logged and treated
  as cache misses before fresh retrieval.
- Isolated the response-cache write so backend exceptions are logged after
  generation without replacing the successful response.
- Added focused route regressions, AST-backed source contracts, project
  guidance, and completed-plan evidence requirements.

## Verification Completed

- The focused cache-degradation tests passed.
- All 46 API tests and every Make gate passed.
- Python compilation, dependency consistency, shell syntax, `git diff --check`,
  and intended-file artifact and secret scans passed.
- The cache-read bypass removal mutation failed.
- The cache-write isolation removal mutation failed.
- The read-regression removal mutation failed.
- The write-regression removal mutation failed.
- The hosted pull-request and CodeQL snapshot is recorded after the
  implementation commit using bounded exact-head queries without polling.
