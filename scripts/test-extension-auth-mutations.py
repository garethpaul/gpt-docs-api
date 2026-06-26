#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUTH_CHECK = ("scripts/check-extension-auth.sh",)
PYTHON_CORS_CHECK = (
    sys.executable,
    "-m",
    "unittest",
    "api.tests.test_app_auth.AppAuthTests.test_authenticated_browser_routes_share_cors_configuration",
)

MUTATIONS = (
    (
        "chrome_extension/content.js",
        '"X-GPT-Docs-API-Key": apiKey',
        '"X-GPT-Docs-API-Key-Broken": apiKey',
        AUTH_CHECK,
    ),
    (
        "chrome_extension/content.js",
        'route !== "/ask" && route !== "/classify/builder"',
        'route !== "/asks" && route !== "/classify/builder"',
        AUTH_CHECK,
    ),
    (
        "chrome_extension/content.js",
        'parsed.protocol !== "https:"',
        'parsed.protocol !== "http:"',
        AUTH_CHECK,
    ),
    (
        "chrome_extension/content.js",
        '{ type: "getClientConfiguration" }',
        '{ type: "getClientConfigurationBroken" }',
        AUTH_CHECK,
    ),
    (
        "chrome_extension/content.js",
        "if (!apiBaseUrl || !apiKey)",
        "if (!apiBaseUrl && !apiKey)",
        AUTH_CHECK,
    ),
    (
        "chrome_extension/background.js",
        "sender.id !== chrome.runtime.id",
        "sender.id === chrome.runtime.id",
        AUTH_CHECK,
    ),
    (
        "chrome_extension/background.js",
        'chrome.storage.session.get(["gptDocsApiKey"]',
        'chrome.storage.local.get(["gptDocsApiKey"]',
        AUTH_CHECK,
    ),
    (
        "chrome_extension/options.js",
        "await storage.session.set({ gptDocsApiKey: normalizedApiKey });",
        "await storage.local.set({ gptDocsApiKey: normalizedApiKey });",
        AUTH_CHECK,
    ),
    (
        "chrome_extension/manifest.json",
        '"storage"',
        '"storage-broken"',
        AUTH_CHECK,
    ),
    (
        "chrome_extension/manifest.json",
        '"minimum_chrome_version": "102"',
        '"minimum_chrome_version": "101"',
        AUTH_CHECK,
    ),
    (
        "chrome_extension/manifest.json",
        '"options_page": "options.html"',
        '"options_page": "options-broken.html"',
        AUTH_CHECK,
    ),
    (
        "api/chalicelib/public/background.js",
        "return true;",
        "return true;\n// hostile mirror divergence",
        AUTH_CHECK,
    ),
    (
        "api/app.py",
        "@app.route('/classify/builder', methods=['POST'], cors=cors_config)",
        "@app.route('/classify/builder', methods=['POST'])",
        PYTHON_CORS_CHECK,
    ),
)


def copy_repository(destination):
    shutil.copytree(
        ROOT,
        destination,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns(".git", "__pycache__", "*.pyc", "*.pyo"),
    )


def apply_mutation(root, relative_path, original, replacement):
    path = root / relative_path
    source = path.read_text(encoding="utf-8")
    if source.count(original) != 1:
        raise RuntimeError(f"mutation anchor is not unique: {relative_path}: {original}")
    path.write_text(source.replace(original, replacement, 1), encoding="utf-8")


def mutation_is_rejected(root, command):
    environment = os.environ.copy()
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    environment["PYTHONPATH"] = str(root / "api")
    if command == AUTH_CHECK:
        invocation = [str(root / command[0])]
    else:
        invocation = list(command)
    result = subprocess.run(
        invocation,
        cwd=root,
        env=environment,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode != 0


def main():
    for relative_path, original, replacement, command in MUTATIONS:
        with tempfile.TemporaryDirectory(prefix="gpt-docs-auth-mutation-") as temp:
            mutation_root = Path(temp) / "repo"
            copy_repository(mutation_root)
            apply_mutation(mutation_root, relative_path, original, replacement)
            if not mutation_is_rejected(mutation_root, command):
                raise SystemExit(f"hostile mutation survived: {relative_path}: {original}")
    print(f"killed {len(MUTATIONS)} hostile extension authentication mutations")


if __name__ == "__main__":
    main()
