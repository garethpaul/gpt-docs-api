# Make Gate Aliases

status: completed

## Context

The repository already had `make test`, `make compile`, `make check`, and
`make verify`, but the local pre-push gate also expects `make lint` and
`make build`. Without those aliases, the first gate command fails before
reaching the existing tests and source baseline.

## Objectives

- Provide stable Makefile targets for lint, test, build, check, and verify.
- Keep `make lint` delegated to the existing source baseline.
- Keep `make build` delegated to the existing compile target.
- Extend the static baseline and docs so the gate targets remain visible.

## Verification

- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
