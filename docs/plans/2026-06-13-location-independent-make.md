# Location-Independent GPT Docs Verification

status: completed

## Context

The maintained baseline originally passed only from the checkout. Rooted
recipes later supported external callers, but GNU Make still split an absolute
Makefile path containing spaces before deriving the checkout root.

## Priority

This is the next isolated reliability gap because local and hosted automation
should be able to load the repository Makefile without first changing
directories. The fix must preserve API behavior, cache semantics, packaging,
dependencies, deployment ownership, and credential boundaries.

## Scope

1. Resolve one validated loaded Makefile as a whole path without Make list
   tokenization and reject startup-variable authority injection.
2. Run test and compile commands from that root.
3. Invoke baseline and Chalice package checkers through rooted paths.
4. Preserve quoted extension-rendering source paths inside the baseline.
5. Add a recursive-safe full-baseline regression for spaced checkout paths,
   completed-plan, external-run, guidance, and hostile-mutation contracts.
6. Preserve API, dependency, IAM, Vercel, and workflow files.

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

- Derived `ROOT` from one shell-quoted, validated loaded `Makefile` path and
  anchored test and compile recipes to that directory, including paths with
  spaces. `MAKEFILES` and overridden `MAKEFILE_LIST` fail before recipes run.
- Invoked baseline and Chalice package verification through absolute rooted
  script paths.
- Added baseline contracts for the rooted command surface, completed plan
  evidence, operator guidance, and a recursive-safe spaced-path full gate.
- Quoted both extension-rendering source paths so that checker no longer splits
  a checkout root containing spaces.
- Documented external-directory behavior in the README and changelog without
  changing API, cache, extension, dependency, IAM, deployment, or workflow
  behavior.

## Verification Completed

- Root and external-directory Make gates passed for `test`, `compile`,
  `check`, `lint`, `build`, and `verify`; each test-bearing gate ran all 46 API
  tests without live credentials.
- Spaced-checkout `make check` passed under GNU Make 4.2 and 4.4 from an
  external caller directory, including the full API and extension baseline.
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
