---
status: completed
---

# Gate runner execution observation

## Problem

The repository's verification gates asserted that source text exists far more
often than they observed a runner execute and *gate*. Three concrete gaps:

1. **The planted-defect control ran nowhere.** `scripts/test-extension-auth-mutations.py`
   applies 13 hostile mutations and asserts each is rejected -- a genuine
   rung-6 control. It was reachable only through `make mutations`, which no CI
   step, no `make verify` prerequisite, and no baseline line ever invoked. Only
   the *existence* of the file was asserted. Because nothing ran it, the
   detection power of `scripts/check-extension-auth.sh` was unguarded: that
   script's content was never pinned, only executed.

   Measured: deleting one assertion from `check-extension-auth.sh` and then
   breaking the real `X-GPT-Docs-API-Key` header in both `content.js` copies
   left `make check` GREEN (exit 0), printing
   `GPT Docs extension authentication checks passed.` `make mutations` caught it
   (exit 2) -- but nothing invoked `make mutations`.

2. **No neuter rejection on the line invoking the checker.** The Makefile
   contract used substring pins (`grep -Fq`). `"$(ROOT)/scripts/check-baseline.sh"`
   is a prefix of `"$(ROOT)/scripts/check-baseline.sh" || true`, so the pin
   passed byte-identically against a neutered runner. An in-gate pin cannot
   close this on its own invoking line: the baseline would detect the neuter,
   print it, and have its non-zero status swallowed by the very `|| true` it
   reported.

   Measured: with `|| true` appended to the `check:` recipe, an inverted
   `hmac.compare_digest` authentication comparison produced
   `FAILED (failures=9, errors=3)` and `make check` exited **0**.

3. **A self-satisfying target-name pin.** The pin for `lint:` did not include
   its prerequisite, so `lint: check` could be reduced to `lint:` -- still
   matching `grep -Fq "lint:"` -- turning the documented `make lint` gate into
   `Nothing to be done for 'lint'.` at exit 0, with `make check` green.

## Change

- Added `scripts/check-gate-integrity.py`: an out-of-band observer that pins
  every Makefile gate line verbatim (prerequisites included), requires each gate
  target to be defined exactly once (a duplicate definition silently overrides
  the real recipe), rejects exit-status-discarding neuters (`|| true`, `|| :`,
  `|| exit 0`, `set +e`, leading `-`, `.IGNORE`) in recipe lines, pins the CI run
  lines verbatim, rejects `continue-on-error` anywhere in the workflow, and pins
  the baseline's own `set -eu` and runner lines.
- Wired two new independent CI steps: `python scripts/check-gate-integrity.py`
  (invoked **directly**, never through `make`, so a neutered recipe cannot
  discard its verdict) and `make mutations` (the planted-defect control).
- Converted the baseline's Makefile target and recipe pins from substring to
  whole-line (`grep -Fxq`), including prerequisites and recipe bodies.
- Added baseline pins for the CI run lines (whole-line), `continue-on-error`
  rejection, the mutation harness's teeth (its survival check and a minimum of
  13 retained mutations), and the gate integrity observer's rules.

## Why two independent steps

Each observer sits outside the other's blast radius:

- `make check` (baseline) pins the Makefile `mutations:` recipe and the
  workflow's `run: make mutations` line. Neutering the mutation runner turns
  `make check` red.
- The gate integrity step and `make mutations` run in separate steps, invoked
  outside the `check:` recipe. Neutering `make check` turns the gate integrity
  step red -- it does not depend on the status it observes.

A single in-gate pin, or a single CI step, cannot achieve this: `continue-on-error`
placed after a `run:` preserves adjacency (so a block pin still matches) while
discarding the verdict exactly as `|| true` does, which is why it is rejected
outright rather than pinned around.

## Bootstrap limit

A repository gate cannot detect its own *total* disconnection. Neutering the run
lines of both independent steps in a single commit defeats any in-repo control;
required status checks / branch protection are the out-of-repo control for that
case. This is stated rather than solved.

## Verification Completed

- `make check` passed on a clean tree (65 API tests, exit 0).
- `make mutations` passed on a clean tree: `killed 13 hostile extension authentication mutations`.
- `python scripts/check-gate-integrity.py` passed on a clean tree.
- Failure injection, both directions, each mutation applied by hand and confirmed
  to parse and run:
  - `|| true` appended to the `check:` recipe: gate integrity observer and
    baseline both exit 1. The verbatim gate-line pin reports first
    (`Makefile must preserve this gate line verbatim`); the recipe neuter scan is
    the backstop for recipes reached another way. Before this change the
    substring pin passed and `make check` exited 0 with
    `FAILED (failures=9, errors=3)` printed.
  - `lint: check` reduced to `lint:`: whole-line pin and observer both exit 1;
    before this change `grep -Fq "lint:"` passed.
  - `run: make mutations` deleted from the workflow: baseline and observer both
    exit 1.
  - `continue-on-error: true` added after `run: make check`: baseline and
    observer both exit 1.
  - `X-GPT-Docs-API-Key` assertion deleted from `check-extension-auth.sh` and the
    real header broken in both `content.js` copies: `make check` still exits 0
    (it does not pin that script's content), while `make mutations` exits 2
    (`hostile mutation survived`) -- and that control now runs in CI, so the
    pipeline is red.
  - A second `check:` target appended with an `@true` recipe: caught by both the
    observer and the baseline (`must define the check gate exactly once; found 2`).
    Whole-line pins alone missed this -- every pinned line was still present and
    no neuter token appeared, while make silently overrode the real recipe.
  - `set -eu` reduced to `set -u` in `check-baseline.sh`: caught by the observer.
    Measured before that rule existed: `make check` exited 0 with an inverted
    authentication comparison in place.
  - `|| true` appended to the baseline's `unittest discover` line: caught by the
    observer's verbatim runner-line pin.
  - Mutation harness gutted from 13 mutations to 1: caught by the baseline
    (`must retain at least 13 hostile mutations; found 1`).
  - `|| true` appended to the observer's OWN CI run line: caught by the baseline's
    whole-line run pin (the observer cannot save itself there).
- No live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, browser
  publication, or deployment operation was executed.
