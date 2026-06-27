#!/usr/bin/env python3
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CHILD_MARKER = "GPT_DOCS_API_MAKE_SPACE_CHILD"


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
        environment[CHILD_MARKER] = "1"
        subprocess.run(
            [
                environment.get("GPT_DOCS_API_MAKE", "make"),
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
