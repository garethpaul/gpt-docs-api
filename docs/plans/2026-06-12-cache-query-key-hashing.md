# Cache Query-Key Hashing

status: completed

## Context

The API accepts queries up to 4,000 characters and currently stores the raw
query in DynamoDB's `query_string` partition-key attribute. DynamoDB string
partition keys are byte-limited, so an otherwise valid long query, especially
one containing multi-byte Unicode, can exceed the storage key boundary and
turn a cache lookup into a route-level 500 response.

Raw query keys also expose user questions in DynamoDB key material, indexes,
diagnostics, and operational tooling even though the cache only needs stable
equality identity.

## Priority

Every authenticated `/ask` request checks the cache before retrieval or model
work. Cache identity must be fixed-size, deterministic, and privacy-minimizing
for every query accepted by request validation.

## Prioritized Engineering Backlog

1. Hash normalized query cache keys with SHA-256 now.
2. Add bounded retries or graceful cache bypass for transient DynamoDB failures
   if production availability requirements are defined.
3. Separate cache data from API code deployment only if the project gains a
   formal infrastructure lifecycle.

## Requirements

- R1. Cache reads and writes must derive the same fixed-size SHA-256 identity
  from UTF-8 query text.
- R2. The existing DynamoDB table and `query_string` key attribute must remain
  compatible; no migration or new table is required.
- R3. Raw query text must not be written as DynamoDB key material.
- R4. Empty, long, and multi-byte strings must produce deterministic bounded
  keys without raising encoding errors.
- R5. Existing TTL validation, expiration behavior, response shape, and route
  cache semantics must remain unchanged.
- R6. Tests, static contracts, and maintenance docs must detect regressions to
  raw query keys.

## Implementation Units

### U1. Centralize cache identity

- **Files:** `api/chalicelib/cache.py`
- Add a small `cache_key(query)` helper returning a namespaced SHA-256 hex
  digest and use it for both `get_item` and `put_item` key values.

### U2. Add deterministic regressions

- **Files:** `api/tests/test_cache.py`, `scripts/check-baseline.sh`
- Verify identical input stability, distinct query separation, Unicode and
  long-query support, fixed key length, and absence of plaintext in calls.

### U3. Update maintenance documentation

- **Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`
- Record fixed-size privacy-minimizing cache identity and unchanged TTL/table
  behavior.

## Scope Boundaries

- Do not change request query normalization or the 4,000-character limit.
- Do not change the DynamoDB table name or primary-key attribute name.
- Do not persist raw query text in a new attribute.
- Do not add a new dependency or change OpenAI/Pinecone behavior.

## Verification

- `make verify`
- `PYTHONPATH=api python -m unittest discover -s api/tests`
- `python -m compileall -q api/app.py api/chalicelib api/tests`
- `python -m pip check`
- `git diff --check`
- Mutations restoring raw query strings in `get_item` or `put_item` calls must
  fail the repository contract.

Completed on 2026-06-12 with the full `make verify` gate, dependency
consistency, focused cache tests, bytecode compilation, and diff hygiene checks
passing.
