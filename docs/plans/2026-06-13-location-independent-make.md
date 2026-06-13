# Location-Independent GPT Docs Verification

status: planned

## Context

The maintained baseline passes from the checkout but Make targets fail when
the absolute Makefile is invoked from another working directory. Test,
compile, checker, and packaging paths are caller-relative.

## Priority

This is the next isolated reliability gap because local and hosted automation
should be able to load the repository Makefile without first changing
directories. The fix must preserve API behavior, cache semantics, packaging,
dependencies, deployment ownership, and credential boundaries.

## Scope

1. Derive the repository root from `MAKEFILE_LIST`.
2. Run test and compile commands from that root.
3. Invoke baseline and Chalice package checkers through rooted paths.
4. Add completed-plan, external-run, guidance, and hostile-mutation contracts.
5. Preserve API, extension, dependency, IAM, Vercel, and workflow files.

## Verification Plan

- Run all 46 API tests, every Make gate, Python compilation, dependency
  consistency, shell syntax, and `git diff --check`.
- Run test, compile, check, lint, build, and verify from /tmp through the
  absolute Makefile path; run package-check when dependencies are available.
- Reject root, test, compile, checker, package-check, plan-status/evidence, and
  documentation mutations.
- Inspect exact intended paths, secrets, and generated artifacts.

## Risk And Rollback

The change affects only verification path resolution. Rollback restores
caller-relative recipes; no runtime state or persistent migration exists.

## Work Completed

Pending implementation.

## Verification Completed

Pending implementation and validation. Run `make check` before completion.
