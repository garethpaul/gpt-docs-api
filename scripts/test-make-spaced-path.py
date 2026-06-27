#!/usr/bin/env python3
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CHILD_MARKER = "GPT_DOCS_API_MAKE_SPACE_CHILD"


def make_command(make, copied_root, caller_root, *arguments, environment=None):
    return subprocess.run(
        [make, "--no-print-directory", "-f", str(copied_root / "Makefile"), *arguments],
        cwd=caller_root,
        env=environment,
        capture_output=True,
        text=True,
        timeout=180,
    )


def main():
    if os.environ.get(CHILD_MARKER) == "1":
        return

    tracked_files = subprocess.check_output(
        ["git", "-C", str(ROOT), "ls-files", "-z"]
    ).decode().rstrip("\0").split("\0")

    with tempfile.TemporaryDirectory(prefix="gpt-docs-api-make-space-") as temporary:
        temporary_root = Path(temporary)
        copied_root = temporary_root / "repository with spaces"
        caller_root = temporary_root / "external caller"
        shutil.copytree(
            ROOT,
            copied_root,
            ignore=shutil.ignore_patterns(".git", "__pycache__", "*.pyc", "*.pyo"),
        )
        caller_root.mkdir()
        subprocess.run(["git", "-C", copied_root, "init", "-q"], check=True)
        subprocess.run(
            ["git", "-C", copied_root, "add", "-N", "--", *tracked_files],
            check=True,
        )

        environment = os.environ.copy()
        make = environment.get("GPT_DOCS_API_MAKE", "make")
        root_result = make_command(
            make,
            copied_root,
            caller_root,
            "--eval",
            'print-root:;@printf "%s\\n" "$(ROOT)"',
            "print-root",
            environment=environment,
        )
        if root_result.returncode != 0 or root_result.stdout.strip() != str(copied_root.resolve()):
            raise AssertionError("spaced Makefile invocation resolved the wrong repository root")

        extra_makefile = temporary_root / "extra.mk"
        extra_makefile.write_text("all:\n\t@:\n")
        hostile_environment = environment.copy()
        hostile_environment["MAKEFILES"] = str(extra_makefile)
        hostile_result = make_command(
            make, copied_root, caller_root, "check", environment=hostile_environment
        )
        if hostile_result.returncode == 0 or "MAKEFILES must be empty" not in hostile_result.stderr:
            raise AssertionError("MAKEFILES contamination must fail closed")

        list_override_result = make_command(
            make, copied_root, caller_root, "MAKEFILE_LIST=hostile", "check", environment=environment
        )
        if list_override_result.returncode == 0 or "MAKEFILE_LIST must not be overridden" not in list_override_result.stderr:
            raise AssertionError("MAKEFILE_LIST override must fail closed")

        environment[CHILD_MARKER] = "1"
        subprocess.run(
            [
                make,
                "-f",
                str(copied_root / "Makefile"),
                "check",
            ],
            cwd=caller_root,
            env=environment,
            check=True,
            timeout=180,
        )


if __name__ == "__main__":
    main()
