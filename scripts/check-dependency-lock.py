#!/usr/bin/env python3
import re
import sys
from pathlib import Path


DIRECT_REQUIREMENTS = {
    "boto3==1.43.18",
    "chalice==1.33.0",
    "openai==0.28.1",
    "pinecone-client[grpc]==2.2.4",
}
LOCK_COMMAND = (
    "uv pip compile api/requirements.in --python-version 3.10 "
    "--python-platform x86_64-manylinux_2_28 --exclude-newer 2026-06-15 "
    "--generate-hashes "
    "--no-annotate --output-file api/requirements.txt"
)
EXPECTED_PACKAGE_COUNT = 47
PACKAGE = re.compile(r"^([A-Za-z0-9_.-]+)==([^\s\\]+) \\$")
HASH = re.compile(r"^    --hash=sha256:[0-9a-f]{64}(?: \\)?$")


def logical_entries(lines):
    entries = []
    current = []
    for line in lines:
        if PACKAGE.fullmatch(line):
            if current:
                entries.append(current)
            current = [line]
        elif current and line.startswith("    --hash="):
            current.append(line)
        elif line and not line.startswith("#"):
            raise SystemExit(f"Unexpected dependency lock line: {line}")
    if current:
        entries.append(current)
    return entries


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: check-dependency-lock.py REQUIREMENTS_IN REQUIREMENTS_LOCK")

    input_path = Path(sys.argv[1])
    lock_path = Path(sys.argv[2])
    direct = {line for line in input_path.read_text().splitlines() if line}
    if direct != DIRECT_REQUIREMENTS:
        raise SystemExit("Direct dependency input must preserve the four reviewed exact pins.")

    lock_lines = lock_path.read_text().splitlines()
    if LOCK_COMMAND not in "\n".join(lock_lines[:4]):
        raise SystemExit(
            "Dependency lock must record the Python 3.10 manylinux regeneration command."
        )

    entries = logical_entries(lock_lines)
    if len(entries) != EXPECTED_PACKAGE_COUNT:
        raise SystemExit(
            f"Dependency lock must contain {EXPECTED_PACKAGE_COUNT} reviewed packages."
        )

    packages = {}
    for entry in entries:
        match = PACKAGE.fullmatch(entry[0])
        name = match.group(1).lower().replace("_", "-")
        if name in packages:
            raise SystemExit(f"Dependency lock contains duplicate package: {name}")
        hashes = entry[1:]
        if not hashes or any(not HASH.fullmatch(line) for line in hashes):
            raise SystemExit(f"Dependency lock package lacks valid SHA-256 hashes: {name}")
        malformed_continuation = any(
            not line.endswith(" \\") for line in hashes[:-1]
        ) or hashes[-1].endswith(" \\")
        if malformed_continuation:
            raise SystemExit(f"Dependency lock hash continuations are malformed: {name}")
        packages[name] = match.group(2)

    for name, version in {
        "boto3": "1.43.18",
        "chalice": "1.33.0",
        "openai": "0.28.1",
        "pinecone-client": "2.2.4",
    }.items():
        if packages.get(name) != version:
            raise SystemExit(f"Dependency lock changed reviewed direct pin: {name}")

    print(f"Dependency lock contains {len(packages)} exact, hash-addressed packages.")


if __name__ == "__main__":
    main()
