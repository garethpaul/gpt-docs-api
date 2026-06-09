# Query Length Boundary

status: completed

## Context

`/ask` and `/classify/builder` already reject missing, whitespace-only, and
non-string query values before spending OpenAI, Pinecone, DynamoDB, or cache
work. They did not enforce an upper bound on otherwise valid query strings.

## Completed Scope

- Added `MAX_QUERY_LENGTH` to the pure request utility module.
- Rejected stripped query strings longer than the configured maximum.
- Added utility coverage for accepted maximum-length and rejected overlong query
  payloads.
- Extended the source baseline and docs so the boundary stays visible.

## Verification

- `PYTHONPATH=api python -m unittest api.tests.test_utils`
- `scripts/check-baseline.sh`
- `make verify`
- `git diff --check`
