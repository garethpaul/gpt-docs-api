# Location-Independent GPT Docs Verification

status: completed

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

- Derived `ROOT` from the loaded `Makefile` and anchored test and compile
  recipes to that directory.
- Invoked baseline and Chalice package verification through absolute rooted
  script paths.
- Added baseline contracts for the rooted command surface, completed plan
  evidence, and operator guidance.
- Documented external-directory behavior in the README and changelog without
  changing API, cache, extension, dependency, IAM, deployment, or workflow
  behavior.

## Verification Completed

- Root and external-directory Make gates passed for `test`, `compile`,
  `check`, `lint`, `build`, and `verify`; each test-bearing gate ran all 46 API
  tests without live credentials.
- Local package-check reached the explicit Chalice availability guard
  and exited before package construction because the `chalice` command is not
  installed in this checkout environment. The unchanged hosted workflow owns
  the dependency-backed package build and archive inspection.
- The root-derivation mutation failed.
- The test-command mutation failed.
- The compile-command mutation failed.
- The checker-path mutation failed.
- The package-check-path mutation failed.
- The plan-evidence mutation failed.
- The documentation mutation failed.
- Shell syntax, Python compilation, pinned dependency contracts, diff hygiene,
  intended-path review, secret scanning, and generated-artifact inspection
  passed.
