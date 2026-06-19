# Validate Cached Response Data

status: completed

## Context

`get_cached_response` validates cache expiry but returns any remaining DynamoDB
item shape. `/ask` then indexes `response` and `links` directly, so malformed or
legacy entries can turn an otherwise valid request into a generic 500 instead
of a cache miss. Cached links also bypass the HTTPS Twilio-host policy applied
to newly retrieved citations, allowing pre-hardening cache data to retain a
different trust boundary from fresh responses.

## Priority

Every authenticated `/ask` request checks DynamoDB before retrieval or model
work. Persisted data must be treated as untrusted at read time, and cache hits
must preserve the same citation policy as freshly generated answers.

## Scope

1. Accept cache hits only when `response` is a string and `links` is a list of
   strings; treat missing or malformed payload fields as a cache miss.
2. Centralize HTTPS Twilio citation filtering and apply it to both fresh
   retrieval results and valid cache hits.
3. Add cache and route regressions for malformed entries, legacy external
   links, duplicate links, and model-work avoidance on a valid cache hit.
4. Extend the maintained baseline and synchronize cache-boundary documentation.

## Verification Plan

- Run focused and full API tests, compilation, dependency consistency, all
  standard Make gates including `make verify` and `make package-check`, shell
  syntax, diff checks, and intended-file artifact and secret scans.
- Remove cache payload validation, bypass cached-link filtering, and remove each
  regression contract; every hostile mutation must fail.
- Push a stacked pull request and take bounded exact-head workflow, check, and
  CodeQL snapshots without an unbounded polling loop.

## Risk And Rollback

Malformed entries become misses and may trigger a fresh paid model request;
valid entries keep the existing table schema and response body. Legacy cached
links outside the current Twilio policy are omitted. Rollback restores direct
trust in persisted cache payloads and their historical links; no migration is
required.

## Work Completed

- Required cache entries to contain a string `response` and a list of string
  `links`; malformed persisted payloads now become cache misses.
- Centralized deterministic HTTPS Twilio-host filtering and applied it to both
  fresh retrieval results and valid cache hits.
- Added direct cache-shape coverage and an authenticated route regression that
  removes legacy external, HTTP, and duplicate links without invoking model or
  cache-write work.
- Extended the maintained source/test contracts and synchronized the README,
  vision, and change history.

## Verification Completed

- The focused malformed-cache and cached-citation tests passed.
- All 44 API tests and every Make gate passed in an isolated Python 3.10
  environment with no broken requirements.
- Credential-isolated Chalice package verification passed with 5,335 archive
  entries and one scoped Python 3.10 function.
- Cache payload-validation removal failed all five malformed-shape subtests.
- Cached-link filtering removal failed the authenticated route regression.
- Regression-test removal failed the maintained route-test contract.
- Python compilation, shell syntax, diff checks, intended-file artifact checks,
  and secret-pattern scans passed.
- The hosted pull-request and CodeQL snapshot is recorded separately after
  push; this plan claims only the completed pre-push verification above.
