#!/usr/bin/env python3
"""Out-of-band observer for the Make gate and CI wiring.

This script is invoked DIRECTLY by its own CI step -- never through `make` --
so its exit status cannot be discarded by a neutered Make recipe. It exists to
answer the questions the in-gate pins structurally cannot answer about
themselves:

* Does every gate recipe still propagate its runner's exit status, or has a
  ``|| true``-style neuter been appended to the line that invokes the checker?
  An in-gate pin cannot catch that on its own invoking line: it would detect the
  violation, print it, and then have its own non-zero status swallowed by the
  very neuter it just reported.
* Does CI still invoke every gate runner, with its verdict intact
  (no ``continue-on-error``)?

`scripts/check-baseline.sh` pins this file's rules and this script pins the
workflow lines that run `make check`, so the two independent CI steps observe
each other. Neither sits inside the other's blast radius.

Bootstrap limit: a repository gate cannot detect its own *total* disconnection.
Neutering the run lines of BOTH independent steps in a single commit defeats
any in-repo control; required status checks / branch protection are the
out-of-repo control for that case.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAKEFILE = ROOT / "Makefile"
WORKFLOW = ROOT / ".github" / "workflows" / "check.yml"
BASELINE = ROOT / "scripts" / "check-baseline.sh"
PACKAGE_CHECK = ROOT / "scripts" / "verify-chalice-package.sh"

# The baseline's own error propagation. Stripping "set -e" leaves every runner
# executing and every in-baseline pin passing, while the script's exit status
# collapses to that of its final printf -- the suite prints failures and
# `make check` still exits 0. The baseline cannot pin this about itself for the
# same reason it cannot pin its own invoking line, so this out-of-band step does.
REQUIRED_BASELINE_LINES = (
    "set -eu",
    'PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$ROOT_DIR/api" python -m unittest discover -s "$ROOT_DIR/api/tests"',
    'python "$SYNTAX_CHECK" "$ROOT_DIR/api/app.py" "$ROOT_DIR/api/chalicelib" "$ROOT_DIR/api/tests"',
    'python3 "$GATE_INTEGRITY_CHECK"',
    '"$EXTENSION_RENDERING_CHECK"',
    '"$EXTENSION_AUTH_CHECK"',
    'PYTHONDONTWRITEBYTECODE=1 python "$MAKE_SPACED_PATH_CHECK"',
)

# Whole-line, byte-exact Makefile contract. Prerequisites are part of the
# pinned text: a bare "lint:" satisfies a substring pin for "lint:" while
# silently dropping the gate it aliases.
REQUIRED_MAKEFILE_LINES = (
    ".PHONY: build check compile lint mutations package-check test verify",
    "lint: check",
    "test:",
    '\t@cd "$(ROOT)" && PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=api python -m unittest discover -s api/tests',
    "build: compile",
    "compile:",
    '\t@cd "$(ROOT)" && python "$(ROOT)/scripts/check-python-syntax.py" api/app.py api/chalicelib api/tests',
    "mutations:",
    '\t@cd "$(ROOT)" && PYTHONDONTWRITEBYTECODE=1 python "$(ROOT)/scripts/test-extension-auth-mutations.py"',
    "check:",
    '\t@"$(ROOT)/scripts/check-baseline.sh"',
    "package-check:",
    '\t@"$(ROOT)/scripts/verify-chalice-package.sh"',
    "verify: test compile check",
)

# Whole-line, byte-exact workflow run lines, including indentation. A substring
# pin for "make check" also matches "make check || true".
REQUIRED_WORKFLOW_LINES = (
    "        run: python scripts/check-gate-integrity.py",
    "        run: make package-check",
    "        run: make check",
    "        run: make mutations",
)

# Constructs that keep a command running while discarding its verdict.
STATUS_DISCARD_PATTERNS = (
    (re.compile(r"\|\|\s*true\b"), "|| true"),
    (re.compile(r"\|\|\s*:"), "|| :"),
    (re.compile(r"\|\|\s*exit\s+0\b"), "|| exit 0"),
    (re.compile(r";\s*exit\s+0\b"), "; exit 0"),
    (re.compile(r"\|\|\s*/bin/true\b"), "|| /bin/true"),
    (re.compile(r"set\s+\+e\b"), "set +e"),
)


def fail(message):
    print(f"gate integrity: {message}", file=sys.stderr)
    raise SystemExit(1)


def check_makefile_lines(lines):
    for required in REQUIRED_MAKEFILE_LINES:
        if required not in lines:
            fail(
                "Makefile must preserve this gate line verbatim "
                f"(prerequisites and exit-status propagation included): {required!r}"
            )


def check_makefile_recipes(lines):
    """Every recipe line must propagate its command's exit status."""
    for line in lines:
        if not line.startswith("\t"):
            continue
        for pattern, label in STATUS_DISCARD_PATTERNS:
            if pattern.search(line):
                fail(
                    f"Makefile recipe discards its runner's exit status via {label!r}: {line!r}"
                )
        # A leading '-' tells make to ignore the command's failure.
        command = line.lstrip("\t").lstrip("@+")
        if command.startswith("-"):
            fail(f"Makefile recipe ignores errors via a leading '-': {line!r}")


GATE_TARGETS = (
    "lint",
    "test",
    "build",
    "compile",
    "mutations",
    "check",
    "package-check",
    "verify",
)


def check_single_definitions(lines):
    """Each gate target must be defined exactly once.

    Presence pins are append-blind: a *second* ``check:`` target whose recipe is
    ``@true`` leaves every pinned line intact and introduces no neuter token,
    while GNU make silently overrides the real recipe with the last definition
    and takes the gate dark at exit 0.
    """
    for target in GATE_TARGETS:
        pattern = re.compile(rf"^{re.escape(target)}\s*::?(?!=)")
        definitions = [line for line in lines if pattern.match(line)]
        if len(definitions) != 1:
            fail(
                f"Makefile must define the {target!r} gate exactly once; found "
                f"{len(definitions)} definitions: {definitions!r}. A later "
                "definition silently overrides the real recipe."
            )


def check_makefile_ignore_directives(text):
    if re.search(r"(?m)^\.IGNORE\b", text):
        fail("Makefile must not declare .IGNORE; gate failures must propagate.")
    if re.search(r"(?m)^MAKEFLAGS\s*[+:]?=.*\bi\b", text):
        fail("Makefile must not set an ignore-errors MAKEFLAGS default.")


def check_workflow(text, lines):
    for required in REQUIRED_WORKFLOW_LINES:
        if required not in lines:
            fail(
                "CI workflow must invoke this gate runner on a verbatim run line: "
                f"{required!r}"
            )
    # continue-on-error preserves adjacency -- a two-line block pin still
    # matches -- while discarding the step's verdict exactly as '|| true' does.
    if "continue-on-error" in text:
        fail(
            "CI workflow must not use continue-on-error: it discards a gate "
            "step's verdict while leaving the command running."
        )
    for line in lines:
        stripped = line.strip()
        if not stripped.startswith("run:"):
            continue
        for pattern, label in STATUS_DISCARD_PATTERNS:
            if pattern.search(stripped):
                fail(f"CI run line discards its gate's exit status via {label!r}: {line!r}")


def check_baseline_propagation():
    """The baseline and package gate must keep failures fatal."""
    for script, label in ((BASELINE, "scripts/check-baseline.sh"),
                          (PACKAGE_CHECK, "scripts/verify-chalice-package.sh")):
        if not script.is_file():
            fail(f"{label} is missing.")
        text = script.read_text(encoding="utf-8")
        if "set -eu" not in text.split("\n"):
            fail(f"{label} must keep 'set -eu' so a failing runner is fatal.")
        if re.search(r"(?m)^\s*set\s+\+e\b", text):
            fail(f"{label} must not relax errexit with 'set +e'.")

    baseline_lines = BASELINE.read_text(encoding="utf-8").split("\n")
    for required in REQUIRED_BASELINE_LINES:
        if required not in baseline_lines:
            fail(
                "scripts/check-baseline.sh must execute this runner on a verbatim, "
                f"status-propagating line: {required!r}"
            )


def check_independent_steps(text):
    """The observers must stay in separate steps to stay out-of-band."""
    gate_runs = (
        "run: python scripts/check-gate-integrity.py",
        "run: make check",
        "run: make mutations",
    )
    for run in gate_runs:
        if text.count(run) != 1:
            fail(f"CI workflow must invoke {run!r} exactly once, in its own step.")


def main():
    if not MAKEFILE.is_file():
        fail("Makefile is missing.")
    if not WORKFLOW.is_file():
        fail("CI workflow .github/workflows/check.yml is missing.")

    makefile_text = MAKEFILE.read_text(encoding="utf-8")
    makefile_lines = makefile_text.split("\n")
    workflow_text = WORKFLOW.read_text(encoding="utf-8")
    workflow_lines = workflow_text.split("\n")

    check_makefile_lines(makefile_lines)
    check_single_definitions(makefile_lines)
    check_makefile_recipes(makefile_lines)
    check_makefile_ignore_directives(makefile_text)
    check_workflow(workflow_text, workflow_lines)
    check_independent_steps(workflow_text)
    check_baseline_propagation()

    print("GPT Docs Make gate and CI integrity checks passed.")


if __name__ == "__main__":
    main()
