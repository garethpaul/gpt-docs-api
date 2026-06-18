#!/usr/bin/env python3

from pathlib import Path
import sys


def python_sources(arguments):
    for argument in arguments:
        path = Path(argument)
        if path.is_dir():
            yield from sorted(path.rglob("*.py"))
        elif path.is_file() and path.suffix == ".py":
            yield path
        else:
            raise ValueError(f"Python source path not found: {path}")


def main(arguments):
    if not arguments:
        print("check-python-syntax: no source paths provided", file=sys.stderr)
        return 2

    failed = False
    try:
        sources = python_sources(arguments)
        for path in sources:
            try:
                compile(path.read_bytes(), str(path), "exec")
            except (OSError, SyntaxError) as error:
                print(f"check-python-syntax: {error}", file=sys.stderr)
                failed = True
    except ValueError as error:
        print(f"check-python-syntax: {error}", file=sys.stderr)
        return 2

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
