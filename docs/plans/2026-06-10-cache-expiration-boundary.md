# Cache Expiration Boundary

status: completed

## Context

Every distinct authenticated `/ask` query is stored in DynamoDB without an
expiration timestamp. Cached AI answers can remain stale indefinitely, and
high-cardinality valid queries can grow the cache table without a lifecycle
signal for DynamoDB TTL cleanup.

## Priority

The cache sits behind a public network boundary and stores generated responses.
Entries should have a bounded freshness lifetime and expose a standard epoch
TTL attribute that operators can enable for automatic DynamoDB cleanup.

## Implementation

- Add a one-day cache lifetime constant.
- Store an integer `expires_at` epoch timestamp with each response.
- Treat entries with missing, malformed, or expired timestamps as cache misses.
- Keep time injectable for deterministic tests.
- Add tests for active, expired, missing-expiry, and written TTL behavior.
- Extend the baseline and cache operations documentation.

## Verification

- `PYTHONPATH=api python -m unittest discover -s api/tests`
- `make verify`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
- Mutations accepting expired entries or omitting written TTLs must fail.
- Hosted pinned-dependency Python workflow.
