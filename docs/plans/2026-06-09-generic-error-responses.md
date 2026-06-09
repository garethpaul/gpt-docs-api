# Generic Error Responses

status: completed

## Context

The authenticated `/ask` and `/classify/builder` routes can fail unexpectedly
while calling cache, retrieval, OpenAI, or classification helpers. Returning
`str(error)` to callers can expose upstream details, dependency names, or
configuration mistakes.

## Completed Scope

- Changed unexpected `/ask` and `/classify/builder` failures to log exception
  details server-side and return a generic `Internal server error` body.
- Added route regression tests so unexpected failure details are not echoed to
  callers.
- Extended `scripts/check-baseline.sh` so the route logging, generic error
  responses, tests, docs, and completed plan stay in place.
- Documented the behavior in README, VISION, SECURITY, and CHANGES.

## Verification

- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
