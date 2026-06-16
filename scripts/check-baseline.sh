#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAKEFILE="$ROOT_DIR/Makefile"
README="$ROOT_DIR/README.md"
VISION="$ROOT_DIR/VISION.md"
CHANGES="$ROOT_DIR/CHANGES.md"
REQUIREMENTS="$ROOT_DIR/api/requirements.txt"
REQUIREMENTS_INPUT="$ROOT_DIR/api/requirements.in"
IAM_POLICY="$ROOT_DIR/api/iam-policy.json"
APP="$ROOT_DIR/api/app.py"
AUTH="$ROOT_DIR/api/chalicelib/auth.py"
CACHE="$ROOT_DIR/api/chalicelib/cache.py"
CLASSIFICATION="$ROOT_DIR/api/chalicelib/classification.py"
CONFIG="$ROOT_DIR/api/chalicelib/config.py"
UTILS="$ROOT_DIR/api/chalicelib/utils.py"
TEST_APP_AUTH="$ROOT_DIR/api/tests/test_app_auth.py"
TEST_AUTH="$ROOT_DIR/api/tests/test_auth.py"
TEST_CACHE="$ROOT_DIR/api/tests/test_cache.py"
TEST_CLASSIFICATION="$ROOT_DIR/api/tests/test_classification.py"
TEST_UTILS="$ROOT_DIR/api/tests/test_utils.py"
PLAN="$ROOT_DIR/docs/plans/2026-06-08-gpt-docs-api-testability-dependency-baseline.md"
CHECK_PLAN="$ROOT_DIR/docs/plans/2026-06-08-source-baseline-guard.md"
AUTH_PLAN="$ROOT_DIR/docs/plans/2026-06-08-gpt-docs-api-auth-guard.md"
PUBLIC_PLAN="$ROOT_DIR/docs/plans/2026-06-08-public-file-boundary.md"
QUERY_PLAN="$ROOT_DIR/docs/plans/2026-06-09-request-query-validation.md"
QUERY_LENGTH_PLAN="$ROOT_DIR/docs/plans/2026-06-09-query-length-boundary.md"
CLASSIFICATION_PLAN="$ROOT_DIR/docs/plans/2026-06-09-classification-weight-schema.md"
MAKE_GATES_PLAN="$ROOT_DIR/docs/plans/2026-06-09-make-gate-aliases.md"
RETRIEVAL_METADATA_PLAN="$ROOT_DIR/docs/plans/2026-06-09-retrieval-metadata-guard.md"
GENERIC_ERROR_PLAN="$ROOT_DIR/docs/plans/2026-06-09-generic-error-responses.md"
RETRIEVAL_CONTEXT_PLAN="$ROOT_DIR/docs/plans/2026-06-09-retrieval-context-length-guard.md"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CI_PLAN="$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"
CACHE_EXPIRATION_PLAN="$ROOT_DIR/docs/plans/2026-06-10-cache-expiration-boundary.md"
CACHE_KEY_PLAN="$ROOT_DIR/docs/plans/2026-06-12-cache-query-key-hashing.md"
EXTENSION_RENDERING_PLAN="$ROOT_DIR/docs/plans/2026-06-12-safe-extension-rendering.md"
EXTENSION_RENDERING_CHECK="$ROOT_DIR/scripts/check-extension-rendering.sh"
VENDOR_CLEANUP_PLAN="$ROOT_DIR/docs/plans/2026-06-12-chalice-vendor-cleanup.md"
PACKAGE_CHECK="$ROOT_DIR/scripts/verify-chalice-package.sh"
VERCEL_CONFIG="$ROOT_DIR/vercel.json"
VERCEL_PLAN="$ROOT_DIR/docs/plans/2026-06-12-vercel-deployment-ownership.md"
PIP_BOOTSTRAP_PLAN="$ROOT_DIR/docs/plans/2026-06-12-pip-bootstrap-pin.md"
TOTAL_RETRIEVAL_CONTEXT_PLAN="$ROOT_DIR/docs/plans/2026-06-13-total-retrieval-context-boundary.md"
CACHE_RESPONSE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-cached-response-validation.md"
GRACEFUL_CACHE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-graceful-cache-bypass.md"
LOCATION_INDEPENDENT_MAKE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-location-independent-make.md"
DEPENDENCY_LOCK_PLAN="$ROOT_DIR/docs/plans/2026-06-15-hashed-dependency-lock.md"
DEPENDENCY_LOCK_CHECK="$ROOT_DIR/scripts/check-dependency-lock.py"
BINARY_ARTIFACT_PLAN="$ROOT_DIR/docs/plans/2026-06-15-binary-only-dependency-artifacts.md"
RETRIEVAL_MATCHES_PLAN="$ROOT_DIR/docs/plans/2026-06-16-retrieval-matches-container.md"
RETRIEVAL_ACCESSOR_PLAN="$ROOT_DIR/docs/plans/2026-06-16-retrieval-response-accessor.md"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  ".github/workflows/check.yml" \
  "CHANGES.md" \
  "README.md" \
  "SECURITY.md" \
  "VISION.md" \
  "Makefile" \
  "vercel.json" \
  "api/requirements.in" \
  "api/requirements.txt" \
  "api/iam-policy.json" \
  "api/app.py" \
  "api/chalicelib/auth.py" \
  "api/chalicelib/cache.py" \
  "api/chalicelib/classification.py" \
  "api/chalicelib/config.py" \
  "api/chalicelib/utils.py" \
  "api/tests/test_app_auth.py" \
  "api/tests/test_auth.py" \
  "api/tests/test_cache.py" \
  "api/tests/test_classification.py" \
  "api/tests/test_utils.py" \
  "docs/plans/2026-06-08-gpt-docs-api-auth-guard.md" \
  "docs/plans/2026-06-08-gpt-docs-api-testability-dependency-baseline.md" \
  "docs/plans/2026-06-08-public-file-boundary.md" \
  "docs/plans/2026-06-08-source-baseline-guard.md" \
  "docs/plans/2026-06-09-query-length-boundary.md" \
  "docs/plans/2026-06-09-request-query-validation.md" \
  "docs/plans/2026-06-09-classification-weight-schema.md" \
  "docs/plans/2026-06-09-make-gate-aliases.md" \
  "docs/plans/2026-06-09-retrieval-metadata-guard.md" \
  "docs/plans/2026-06-09-generic-error-responses.md" \
  "docs/plans/2026-06-09-retrieval-context-length-guard.md" \
  "docs/plans/2026-06-10-ci-baseline.md" \
  "docs/plans/2026-06-10-cache-expiration-boundary.md" \
  "docs/plans/2026-06-12-cache-query-key-hashing.md" \
  "docs/plans/2026-06-12-safe-extension-rendering.md" \
  "docs/plans/2026-06-12-chalice-vendor-cleanup.md" \
  "docs/plans/2026-06-12-vercel-deployment-ownership.md" \
  "docs/plans/2026-06-12-pip-bootstrap-pin.md" \
  "docs/plans/2026-06-13-total-retrieval-context-boundary.md" \
  "docs/plans/2026-06-13-cached-response-validation.md" \
  "docs/plans/2026-06-13-graceful-cache-bypass.md" \
  "docs/plans/2026-06-13-location-independent-make.md" \
  "docs/plans/2026-06-15-hashed-dependency-lock.md" \
  "docs/plans/2026-06-15-binary-only-dependency-artifacts.md" \
  "docs/plans/2026-06-16-retrieval-matches-container.md" \
  "docs/plans/2026-06-16-retrieval-response-accessor.md" \
  "scripts/check-dependency-lock.py" \
  "scripts/check-extension-rendering.sh" \
  "scripts/verify-chalice-package.sh" \
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

python3 "$DEPENDENCY_LOCK_CHECK" "$REQUIREMENTS_INPUT" "$REQUIREMENTS"

python - "$IAM_POLICY" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as policy_file:
    policy = json.load(policy_file)

statements = {
    (
        statement.get("Effect"),
        tuple(sorted(statement.get("Action", []))),
        statement.get("Resource"),
    )
    for statement in policy.get("Statement", [])
}
expected = {
    (
        "Allow",
        ("dynamodb:GetItem", "dynamodb:PutItem"),
        "arn:aws:dynamodb:*:*:table/gpt_docs",
    ),
    (
        "Allow",
        ("logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"),
        "arn:aws:logs:*:*:*",
    ),
}
if statements != expected:
    raise SystemExit("IAM policy must contain only scoped cache and log writes.")
PY

python - "$VERCEL_CONFIG" <<'PY'
import json
import sys
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if config.get("git", {}).get("deploymentEnabled") is not False:
    raise SystemExit(
        "vercel.json must disable automatic Git deployments for every branch"
    )
if "rewrites" in config:
    raise SystemExit(
        "vercel.json must not route requests to the retired api/index function"
    )
PY

for target in "lint:" "test:" "build: compile" "compile:" "check:" "package-check:" "verify: test compile check"; do
  if ! grep -Fq "$target" "$MAKEFILE"; then
    printf '%s\n' "Makefile must expose target: $target" >&2
    exit 1
  fi
done

for make_contract in \
  'ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))' \
  'cd "$(ROOT)" && PYTHONPATH=api python -m unittest discover -s api/tests' \
  'cd "$(ROOT)" && python -m compileall -q api/app.py api/chalicelib api/tests' \
  '"$(ROOT)/scripts/check-baseline.sh"' \
  '"$(ROOT)/scripts/verify-chalice-package.sh"'; do
  if ! grep -Fq "$make_contract" "$MAKEFILE"; then
    printf '%s\n' "Makefile must preserve location-independent command: $make_contract" >&2
    exit 1
  fi
done

if ! grep -Fxq "/api/vendor/" "$ROOT_DIR/.gitignore"; then
  printf '%s\n' "api/vendor must remain ignored as generated Chalice package input." >&2
  exit 1
fi

tracked_artifacts=$(git -C "$ROOT_DIR" ls-files | grep -E '(^api/vendor/|(^|/)(__pycache__/|[^/]+\.py[co]$)|(^|/)deployment\.zip$|(^|/)\.chalice/(deployments|venv)/)' || true)
if [ -n "$tracked_artifacts" ]; then
  printf '%s\n' "Generated dependency or package artifacts must not be tracked:" >&2
  printf '%s\n' "$tracked_artifacts" >&2
  exit 1
fi

checkout_credential_contract=$(
  awk '
    /uses: actions\/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10/ {
      in_checkout = 1
      next
    }
    in_checkout && /^[[:space:]]+- name:/ {
      in_checkout = 0
    }
    in_checkout && /persist-credentials:/ {
      count += 1
      if ($0 ~ /^[[:space:]]+persist-credentials: false[[:space:]]*$/) {
        valid += 1
      }
    }
    END {
      printf "%d:%d\n", count, valid
    }
  ' "$CI_WORKFLOW"
)

if ! grep -Fq "workflow_dispatch:" "$CI_WORKFLOW" ||
  ! grep -Fq "contents: read" "$CI_WORKFLOW" ||
  ! grep -Fq "cancel-in-progress: true" "$CI_WORKFLOW" ||
  ! grep -Fq "runs-on: ubuntu-24.04" "$CI_WORKFLOW" ||
  ! grep -Fq "timeout-minutes: 15" "$CI_WORKFLOW" ||
  ! grep -Fq "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" "$CI_WORKFLOW" ||
  ! grep -Fq "# v6.0.3" "$CI_WORKFLOW" ||
  [ "$checkout_credential_contract" != "1:1" ] ||
  ! grep -Fq "actions/setup-python@a309ff8b426b58ec0e2a45f0f869d46889d02405" "$CI_WORKFLOW" ||
  ! grep -Fq 'python-version: "3.10"' "$CI_WORKFLOW" ||
  ! grep -Fq "api/requirements.in" "$CI_WORKFLOW" ||
  ! grep -Fq "api/requirements.txt" "$CI_WORKFLOW" ||
  ! grep -Fq "python -m pip install --upgrade pip==26.1.2" "$CI_WORKFLOW" ||
  ! grep -Fq "python -m pip install --require-hashes --only-binary=:all: -r api/requirements.txt" "$CI_WORKFLOW" ||
  ! grep -Fq "python -m pip check" "$CI_WORKFLOW" ||
  ! grep -Fq "make package-check" "$CI_WORKFLOW" ||
  ! grep -Fq "make check" "$CI_WORKFLOW"; then
  printf '%s\n' "GitHub Actions must keep the pinned Python 3.10 dependency and test contract." >&2
  exit 1
fi

python3 - "$CI_WORKFLOW" <<'PY'
import sys
from pathlib import Path

workflow = Path(sys.argv[1]).read_text()
bootstrap = "python -m pip install --upgrade pip==26.1.2"
if workflow.count(bootstrap) != 1:
    raise SystemExit("GitHub Actions must bootstrap exactly one pinned pip version.")
if "python -m pip install --upgrade pip\n" in workflow:
    raise SystemExit("GitHub Actions must not resolve a floating pip upgrade.")
if workflow.count("python -m pip install --upgrade pip") != 1:
    raise SystemExit("GitHub Actions must not add duplicate or alternate pip bootstraps.")
PY

if ! grep -Fq "status: completed" "$PIP_BOOTSTRAP_PLAN" ||
  ! grep -Fq "pip==26.1.2" "$PIP_BOOTSTRAP_PLAN" ||
  ! grep -Fq "Local and external-working-directory verification passed" "$PIP_BOOTSTRAP_PLAN" ||
  ! grep -Fq "hostile mutations rejected" "$PIP_BOOTSTRAP_PLAN"; then
  printf '%s\n' "Pip bootstrap plan must record completed status and verification." >&2
  exit 1
fi

if ! grep -Fq "pip 26.1.2" "$README" ||
  ! grep -Fq "pinned installer bootstrap" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "exact pip bootstrap" "$VISION" ||
  ! grep -Fq "Pinned the hosted pip bootstrap" "$CHANGES"; then
  printf '%s\n' "Repository guidance must document the pinned pip bootstrap boundary." >&2
  exit 1
fi

if ! grep -Fq "scripts/verify-chalice-package.sh" "$MAKEFILE" ||
  ! grep -Fq "mktemp -d" "$PACKAGE_CHECK" ||
  ! grep -Fq "trap cleanup EXIT HUP INT TERM" "$PACKAGE_CHECK" ||
  ! grep -Fq "AWS_EC2_METADATA_DISABLED=true" "$PACKAGE_CHECK" ||
  ! grep -Fq "AWS_ACCESS_KEY_ID=package-verification" "$PACKAGE_CHECK" ||
  ! grep -Fq "AWS_DEFAULT_REGION=us-east-1" "$PACKAGE_CHECK" ||
  ! grep -Fq "AWS_SHARED_CREDENTIALS_FILE=/dev/null" "$PACKAGE_CHECK" ||
  ! grep -Fq "PYTHONNOUSERSITE=1" "$PACKAGE_CHECK" ||
  ! grep -Fq "PIP_REQUIRE_HASHES=1" "$PACKAGE_CHECK" ||
  ! grep -Fq "PIP_ONLY_BINARY=:all:" "$PACKAGE_CHECK" ||
  ! grep -Fq '"$API_DIR/requirements.in"' "$PACKAGE_CHECK" ||
  ! grep -Fq '"$API_DIR/requirements.txt"' "$PACKAGE_CHECK" ||
  ! grep -Fq '"autogen_policy": false' "$PACKAGE_CHECK" ||
  ! grep -Fq "policy-package-verification.json" "$PACKAGE_CHECK" ||
  ! grep -Fq "timeout" "$PACKAGE_CHECK" ||
  ! grep -Fq "chalice package" "$PACKAGE_CHECK" ||
  ! grep -Fq "deployment.zip" "$PACKAGE_CHECK" ||
  ! grep -Fq "sam.json" "$PACKAGE_CHECK" ||
  ! grep -Fq 'function.get("Runtime") != "python3.10"' "$PACKAGE_CHECK" ||
  ! grep -Fq '"dynamodb:GetItem", "dynamodb:PutItem"' "$PACKAGE_CHECK" ||
  ! grep -Fq '"chalice/", "openai/", "pinecone/"' "$PACKAGE_CHECK"; then
  printf '%s\n' "Package verification must remain temporary, bounded, and structural." >&2
  exit 1
fi

sh -n "$PACKAGE_CHECK"

if ! grep -Fq "CACHE_TTL_SECONDS = 86400" "$CONFIG" ||
  ! grep -Fq "GPT_DOCS_API_KEY_ENV = 'GPT_DOCS_API_KEY'" "$CONFIG" ||
  ! grep -Fq "GPT_DOCS_API_KEY_HEADER = 'X-GPT-Docs-API-Key'" "$CONFIG"; then
  printf '%s\n' "Config must declare the caller auth environment variable and header." >&2
  exit 1
fi

if ! grep -Fq "class AuthenticationConfigurationError" "$AUTH" ||
  ! grep -Fq "class AuthenticationError" "$AUTH" ||
  ! grep -Fq "def require_api_key(headers, environ=os.environ)" "$AUTH" ||
  ! grep -Fq "hmac.compare_digest" "$AUTH" ||
  ! grep -Fq "Authorization" "$TEST_AUTH" ||
  ! grep -Fq "GPT_DOCS_API_KEY_HEADER" "$TEST_AUTH"; then
  printf '%s\n' "Auth helper and unit tests must protect the shared-key contract." >&2
  exit 1
fi

if ! grep -Fq "allow_credentials=False" "$APP" ||
  ! grep -Fq "X-GPT-Docs-API-Key" "$APP" ||
  ! grep -Fq "def authorize_request()" "$APP" ||
  ! grep -Fq "unauthorized_response = authorize_request()" "$APP"; then
  printf '%s\n' "Chalice routes must include the auth guard and non-credentialed wildcard CORS." >&2
  exit 1
fi

if ! grep -Fq "def safe_public_file_path(filename)" "$APP" ||
  ! grep -Fq "os.path.realpath" "$APP" ||
  ! grep -Fq "public_root + os.sep" "$APP" ||
  ! grep -Fq "FileNotFoundError" "$APP" ||
  ! grep -Fq "def public_content_type(file_path)" "$APP"; then
  printf '%s\n' "Public file serving must keep path-boundary and content-type helpers." >&2
  exit 1
fi

if ! grep -Fq "def is_twilio_doc_url(url)" "$APP" ||
  ! grep -Fq "urlparse(url)" "$APP" ||
  ! grep -Fq "parsed.hostname" "$APP" ||
  ! grep -Fq "parsed.scheme == 'https'" "$APP" ||
  ! grep -Fq "hostname.endswith('.twilio.com')" "$APP" ||
  ! grep -Fq "filtered_urls = []" "$APP" ||
  ! grep -Fq "if is_twilio_doc_url(url) and url not in filtered_urls:" "$APP" ||
  ! grep -Fq "filtered_urls.append(url)" "$APP" ||
  ! grep -Fq "return sorted(filtered_urls)" "$APP"; then
  printf '%s\n' "Generated answer links must be filtered by HTTPS Twilio host." >&2
  exit 1
fi

if ! grep -Fq "def metadata_text_and_url(item)" "$APP" ||
  ! grep -Fq "isinstance(metadata, dict)" "$APP" ||
  ! grep -Fq "isinstance(text, str)" "$APP" ||
  ! grep -Fq "MAX_RETRIEVAL_CONTEXT_LENGTH = 4000" "$APP" ||
  ! grep -Fq "context[:MAX_RETRIEVAL_CONTEXT_LENGTH]" "$APP" ||
  ! grep -Fq "matches = retrieval_matches(res)" "$APP" ||
  ! grep -Fq "metadata_text_and_url(item)" "$APP"; then
  printf '%s\n' "Retrieval metadata must be validated before answer generation." >&2
  exit 1
fi

if ! grep -Fq "def retrieval_matches(response)" "$APP" ||
  ! grep -Fq "isinstance(matches, (list, tuple))" "$APP" ||
  ! grep -Fq "matches = retrieval_matches(res)" "$APP" ||
  ! grep -Fq "test_make_query_ignores_malformed_matches_containers" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_retrieval_matches_accepts_list_and_tuple" "$TEST_APP_AUTH" ||
  ! grep -Fq 'malformed_matches = (None, "matches", 1, {"metadata": {}})' "$TEST_APP_AUTH"; then
  printf '%s\n' "Retrieval matches containers must be normalized before metadata iteration." >&2
  exit 1
fi

python3 - "$APP" "$TEST_APP_AUTH" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(encoding="utf-8")
tests = Path(sys.argv[2]).read_text(encoding="utf-8")
helper = source[source.index("def retrieval_matches(response)"):source.index("@app.route('/public/")]
required_source = (
    "get_matches = getattr(response, 'get', None)",
    "if callable(get_matches):",
    "matches = get_matches('matches', [])",
    "matches = getattr(response, 'matches', [])",
    "except Exception:",
    "return ()",
)
required_tests = (
    "test_retrieval_matches_handles_unsupported_accessors",
    "test_make_query_uses_query_only_prompt_after_accessor_failure",
    "NonCallableGetResponse",
    "RaisingGetResponse",
    "RaisingMatchesResponse",
)
if any(contract not in helper for contract in required_source):
    raise SystemExit("Retrieval response access must fail safely before container validation.")
if "hasattr(response, 'get')" in helper:
    raise SystemExit("Retrieval response access must not call an unverified get attribute.")
if any(contract not in tests for contract in required_tests):
    raise SystemExit("Retrieval response accessor regressions must remain registered.")
PY

if ! grep -Fq 'RETRIEVAL_CONTEXT_SEPARATOR = "\n\n---\n\n"' "$APP" ||
  ! grep -Fq "remaining_context_length = MAX_RETRIEVAL_CONTEXT_LENGTH" "$APP" ||
  ! grep -Fq "available_length = remaining_context_length - separator_length" "$APP" ||
  ! grep -Fq "bounded_context = context[:available_length]" "$APP" ||
  ! grep -Fq "remaining_context_length -= separator_length + len(bounded_context)" "$APP" ||
  ! grep -Fq "if remaining_context_length == 0:" "$APP"; then
  printf '%s\n' "Retrieval context must enforce one separator-aware total prompt budget." >&2
  exit 1
fi

if ! grep -Fq "logger.exception('Failed to process ask request')" "$APP" ||
  ! grep -Fq "logger.exception('Failed to process classify request')" "$APP" ||
  ! grep -Fq "{'error': 'Internal server error'}" "$APP"; then
  printf '%s\n' "Unexpected route failures must log details and return generic 500 errors." >&2
  exit 1
fi

if ! grep -Fq "test_ask_rejects_unauthenticated_callers_before_body_or_model_work" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_classify_rejects_unauthenticated_callers_before_body_or_model_work" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_serve_public_returns_known_asset_with_content_type" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_serve_public_returns_404_for_missing_asset" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_serve_public_rejects_path_traversal" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_is_twilio_doc_url_requires_https_twilio_host" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_make_query_filters_links_by_twilio_host" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_ask_reapplies_twilio_link_policy_to_cached_response" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_make_query_skips_incomplete_metadata" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_make_query_truncates_overlong_metadata_text" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_make_query_bounds_total_context_and_excludes_unused_links" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_ask_returns_generic_error_for_unexpected_failures" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_classify_returns_generic_error_for_unexpected_failures" "$TEST_APP_AUTH" ||
  ! grep -Fq "assert_not_called" "$TEST_APP_AUTH"; then
  printf '%s\n' "Route tests must cover auth short-circuiting and public-file safety." >&2
  exit 1
fi

if ! grep -Fq "def filter_twilio_doc_urls(urls):" "$APP" ||
  [ "$(grep -Fc 'filter_twilio_doc_urls(' "$APP")" -ne 3 ] ||
  ! grep -Fq "cache_entry.get('response')" "$CACHE" ||
  ! grep -Fq "cache_entry.get('links')" "$CACHE" ||
  ! grep -Fq "any(not isinstance(link, str) for link in links)" "$CACHE" ||
  ! grep -Fq "test_get_cached_response_rejects_malformed_payload_shape" "$TEST_CACHE"; then
  printf '%s\n' "Cache hits must validate payload shape and reuse the current Twilio citation policy." >&2
  exit 1
fi

python - "$APP" "$TEST_APP_AUTH" <<'PY'
import ast
import sys
from pathlib import Path

app_tree = ast.parse(Path(sys.argv[1]).read_text(encoding="utf-8"))
test_tree = ast.parse(Path(sys.argv[2]).read_text(encoding="utf-8"))
ask = next(
    node for node in app_tree.body
    if isinstance(node, ast.FunctionDef) and node.name == "ask_question"
)

def calls_name(node, name):
    return any(
        isinstance(item, ast.Call)
        and isinstance(item.func, ast.Name)
        and item.func.id == name
        for item in ast.walk(node)
    )

def exception_handler(try_node):
    handlers = [
        handler for handler in try_node.handlers
        if isinstance(handler.type, ast.Name) and handler.type.id == "Exception"
    ]
    if len(handlers) != 1:
        raise SystemExit("Cache operations must retain one explicit Exception boundary.")
    return handlers[0]

def logged_message(handler, expected):
    return any(
        isinstance(item, ast.Call)
        and isinstance(item.func, ast.Attribute)
        and isinstance(item.func.value, ast.Name)
        and item.func.value.id == "logger"
        and item.func.attr == "exception"
        and len(item.args) == 1
        and isinstance(item.args[0], ast.Constant)
        and item.args[0].value == expected
        for item in ast.walk(handler)
    )

read_candidates = [
    node for node in ast.walk(ask)
    if isinstance(node, ast.Try) and calls_name(node, "get_cached_response")
]
write_candidates = [
    node for node in ast.walk(ask)
    if isinstance(node, ast.Try) and calls_name(node, "store_in_cache")
]
read_try = min(
    read_candidates,
    key=lambda node: node.end_lineno - node.lineno,
    default=None,
)
write_try = min(
    write_candidates,
    key=lambda node: node.end_lineno - node.lineno,
    default=None,
)
if read_try is None or write_try is None or read_try.lineno >= write_try.lineno:
    raise SystemExit("Cache reads and writes must remain isolated in request order.")

read_handler = exception_handler(read_try)
read_sets_miss = any(
    isinstance(item, ast.Assign)
    and any(isinstance(target, ast.Name) and target.id == "cache_entry" for target in item.targets)
    and isinstance(item.value, ast.Constant)
    and item.value.value is None
    for item in read_handler.body
)
if not read_sets_miss or not logged_message(
    read_handler, "Failed to read response cache; bypassing cache"
):
    raise SystemExit("Cache read failures must be logged and converted to misses.")

write_handler = exception_handler(write_try)
if not logged_message(
    write_handler, "Failed to write response cache; returning generated response"
):
    raise SystemExit("Cache write failures must be logged without replacing the response.")

test_names = {
    node.name for node in ast.walk(test_tree) if isinstance(node, ast.FunctionDef)
}
required_tests = {
    "test_ask_bypasses_cache_read_failure",
    "test_ask_returns_generated_response_when_cache_write_fails",
}
if not required_tests.issubset(test_names):
    raise SystemExit("Cache degradation must retain focused route regressions.")
PY

if ! grep -Fq "def get_cache_table(resource=None)" "$CACHE" ||
  ! grep -Fq "def get_cached_response(query, table=None, now=None)" "$CACHE" ||
  ! grep -Fq "def store_in_cache(query, response, links, table=None, now=None," "$CACHE" ||
  ! grep -Fq "expires_at <= current_time" "$CACHE" ||
  ! grep -Fq "'expires_at': current_time + ttl_seconds" "$CACHE"; then
  printf '%s\n' "Cache helpers must remain injectable for no-credential tests." >&2
  exit 1
fi

if ! grep -Fq "test_import_does_not_create_dynamodb_resource" "$TEST_CACHE" ||
  ! grep -Fq "test_get_cached_response_rejects_expired_or_missing_expiry" "$TEST_CACHE" ||
  ! grep -Fq "test_store_in_cache_rejects_invalid_ttl" "$TEST_CACHE" ||
  ! grep -Fq '"expires_at": 160' "$TEST_CACHE"; then
  printf '%s\n' "Cache tests must cover import safety without DynamoDB resources." >&2
  exit 1
fi

if ! grep -Fq "def cache_key" "$CACHE" ||
  ! grep -Fq "hashlib.sha256(query.encode('utf-8')).hexdigest()" "$CACHE" ||
  ! grep -Fq "Key={'query_string': cache_key(query)}" "$CACHE" ||
  ! grep -Fq "Item={'query_string': cache_key(query)" "$CACHE" ||
  ! grep -Fq "test_cache_key_is_fixed_size_and_deterministic" "$TEST_CACHE" ||
  ! grep -Fq "test_cache_key_handles_long_unicode_without_plaintext" "$TEST_CACHE"; then
  printf '%s\n' "Cache reads and writes must use fixed-size SHA-256 query identities." >&2
  exit 1
fi

if grep -Fq "from chalice" "$UTILS" || grep -Fq "BadRequestError" "$UTILS"; then
  printf '%s\n' "Pure request utility helpers must not import Chalice." >&2
  exit 1
fi

if ! grep -Fq "ValueError('Request body must be JSON')" "$UTILS" ||
  ! grep -Fq "json.JSONDecodeError" "$UTILS" ||
  ! grep -Fq "ValueError('Query must be a string')" "$UTILS" ||
  ! grep -Fq "query = query.strip()" "$UTILS" ||
  ! grep -Fq "MAX_QUERY_LENGTH = 4000" "$UTILS" ||
  ! grep -Fq "ValueError('Query is too long')" "$UTILS"; then
  printf '%s\n' "Utility helpers must preserve request and JSON parsing errors." >&2
  exit 1
fi

if ! grep -Fq 'validate_request_payload({"query": "   "})' "$TEST_UTILS" ||
  ! grep -Fq "Query must be a string" "$TEST_UTILS" ||
  ! grep -Fq "test_validate_request_payload_rejects_overlong_query" "$TEST_UTILS" ||
  ! grep -Fq "test_validate_request_payload_accepts_maximum_length_query" "$TEST_UTILS" ||
  ! grep -Fq "MAX_QUERY_LENGTH + 1" "$TEST_UTILS"; then
  printf '%s\n' "Utility tests must cover whitespace and non-string queries." >&2
  exit 1
fi

if ! grep -Fq "openai_client=openai" "$CLASSIFICATION" ||
  ! grep -Fq "CLASSIFICATION_KEYS = (\"with_code\", \"minimal_code\", \"no_code\")" "$CLASSIFICATION" ||
  ! grep -Fq "def validate_classification_weights" "$CLASSIFICATION" ||
  ! grep -Fq "math.isfinite" "$CLASSIFICATION" ||
  ! grep -Fq "Failed to generate classification" "$CLASSIFICATION"; then
  printf '%s\n' "Classification helpers must keep injectable OpenAI clients, schema validation, and wrapped errors." >&2
  exit 1
fi

if ! grep -Fq "FakeOpenAI" "$TEST_CLASSIFICATION" ||
  ! grep -Fq "test_validate_classification_weights_requires_expected_keys" "$TEST_CLASSIFICATION" ||
  ! grep -Fq "test_validate_classification_weights_rejects_invalid_values" "$TEST_CLASSIFICATION" ||
  ! grep -Fq "test_generate_classification_wraps_malformed_weight_errors" "$TEST_CLASSIFICATION" ||
  ! grep -Fq "extract_json_object_returns_empty_dict_without_stdout" "$TEST_UTILS"; then
  printf '%s\n' "Tests must cover fake OpenAI clients, classification schemas, and quiet JSON parse failures." >&2
  exit 1
fi

if ! grep -Fq "make verify" "$README" ||
  ! grep -Fq "GitHub Actions" "$README" ||
  ! grep -Fq "make lint" "$README" ||
  ! grep -Fq "make test" "$README" ||
  ! grep -Fq "make build" "$README" ||
  ! grep -Fq "CHANGES.md" "$README" ||
  ! grep -Fq "GPT_DOCS_API_KEY" "$README" ||
  ! grep -Fq "maximum query length" "$README" ||
  ! grep -Fq "public asset routes" "$README" ||
  ! grep -Fq "Twilio link host filtering" "$README" ||
  ! grep -Fq "retrieval metadata guard" "$README" ||
  ! grep -Fq "retrieval context length" "$README" ||
  ! grep -Fq "total retrieval context budget" "$README" ||
  ! grep -Fq "expires_at" "$README" ||
  ! grep -Fq "fixed-size SHA-256 identity" "$README" ||
  ! grep -Fq "generic 500 errors" "$README" ||
  ! grep -Fq "classification weight schema" "$README" ||
  ! grep -Fq "Vercel automatic Git deployments are disabled" "$README" ||
  ! grep -Fq "OpenAI" "$README" ||
  ! grep -Fq "Pinecone" "$README"; then
  printf '%s\n' "README must document verification, changelog, and external service boundaries." >&2
  exit 1
fi

if ! grep -Fq "Run \`make verify\`" "$VISION" ||
  ! grep -Fq "GitHub Actions" "$VISION" ||
  ! grep -Fq "make lint" "$VISION" ||
  ! grep -Fq "make test" "$VISION" ||
  ! grep -Fq "make build" "$VISION" ||
  ! grep -Fq "GPT_DOCS_API_KEY" "$VISION" ||
  ! grep -Fq "maximum query length" "$VISION" ||
  ! grep -Fq "public asset" "$VISION" ||
  ! grep -Fq "Twilio link host filtering" "$VISION" ||
  ! grep -Fq "retrieval metadata guard" "$VISION" ||
  ! grep -Fq "retrieval context length" "$VISION" ||
  ! grep -Fq "total retrieval context budget" "$VISION" ||
  ! grep -Fq "cache expiration" "$VISION" ||
  ! grep -Fq "fixed-size SHA-256 cache keys" "$VISION" ||
  ! grep -Fq "text-only extension rendering" "$VISION" ||
  ! grep -Fq "generic 500 errors" "$VISION" ||
  ! grep -Fq "classification weight schema" "$VISION"; then
  printf '%s\n' "VISION.md must keep the make verify and API auth contribution rules visible." >&2
  exit 1
fi

if ! grep -Fq "Vercel automatic Git deployments" "$VISION"; then
  printf '%s\n' "VISION.md must keep deployment ownership explicit." >&2
  exit 1
fi

if ! grep -Fq "source baseline guard" "$CHANGES" ||
  ! grep -Fq "GitHub Actions" "$CHANGES" ||
  ! grep -Fq "make lint" "$CHANGES" ||
  ! grep -Fq "make test" "$CHANGES" ||
  ! grep -Fq "make build" "$CHANGES" ||
  ! grep -Fq "shared API-key guard" "$CHANGES" ||
  ! grep -Fq "public file path" "$CHANGES" ||
  ! grep -Fq "query validation" "$CHANGES" ||
  ! grep -Fq "maximum query length" "$CHANGES" ||
  ! grep -Fq "Twilio link host filtering" "$CHANGES" ||
  ! grep -Fq "retrieval metadata guard" "$CHANGES" ||
  ! grep -Fq "retrieval context length" "$CHANGES" ||
  ! grep -Fq "total retrieval context budget" "$CHANGES" ||
  ! grep -Fq "cache entries" "$CHANGES" ||
  ! grep -Fq "SHA-256 identities" "$CHANGES" ||
  ! grep -Fq "text-only DOM rendering" "$CHANGES" ||
  ! grep -Fq "generic 500 errors" "$CHANGES" ||
  ! grep -Fq "classification weight schema" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the source baseline and auth guards." >&2
  exit 1
fi

if ! grep -Fq "disabled unintended Vercel Git deployments" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the Vercel deployment boundary." >&2
  exit 1
fi

if ! grep -Fq "absolute Makefile path can be invoked from any working directory" "$README" ||
  ! grep -Fq "package-verification scope" "$README" ||
  ! grep -Fq "Make verification target derive the checkout root" "$CHANGES" ||
  ! grep -Fq "external directories" "$CHANGES"; then
  printf '%s\n' "Project guidance must document location-independent Make verification." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PLAN" ||
  ! grep -Fq "status: completed" "$CHECK_PLAN" ||
  ! grep -Fq "status: completed" "$AUTH_PLAN" ||
  ! grep -Fq "status: completed" "$PUBLIC_PLAN" ||
  ! grep -Fq "status: completed" "$QUERY_PLAN" ||
  ! grep -Fq "status: completed" "$QUERY_LENGTH_PLAN" ||
  ! grep -Fq "status: completed" "$CLASSIFICATION_PLAN" ||
  ! grep -Fq "status: completed" "$MAKE_GATES_PLAN" ||
  ! grep -Fq "status: completed" "$RETRIEVAL_METADATA_PLAN" ||
  ! grep -Fq "status: completed" "$GENERIC_ERROR_PLAN" ||
  ! grep -Fq "status: completed" "$RETRIEVAL_CONTEXT_PLAN" ||
  ! grep -Fq "status: completed" "$CI_PLAN" ||
  ! grep -Fq "status: completed" "$CACHE_EXPIRATION_PLAN" ||
  ! grep -Fq "status: completed" "$CACHE_KEY_PLAN" ||
  ! grep -Fq "status: completed" "$EXTENSION_RENDERING_PLAN" ||
  ! grep -Fq "status: completed" "$VENDOR_CLEANUP_PLAN" ||
  ! grep -Fq "status: completed" "$VERCEL_PLAN" ||
  ! grep -Fq "status: completed" "$TOTAL_RETRIEVAL_CONTEXT_PLAN" ||
  ! grep -Fq "status: completed" "$CACHE_RESPONSE_PLAN" ||
  ! grep -Fq "status: completed" "$GRACEFUL_CACHE_PLAN" ||
  ! grep -Fq "status: completed" "$LOCATION_INDEPENDENT_MAKE_PLAN" ||
  ! grep -Fq "status: completed" "$ROOT_DIR/docs/plans/2026-06-09-twilio-link-host-filtering.md"; then
  printf '%s\n' "Plan documents must be marked completed." >&2
  exit 1
fi

python - "$LOCATION_INDEPENDENT_MAKE_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
statuses = re.findall(r"^status: .+$", plan, flags=re.MULTILINE)
sections = plan.split("## Verification Completed\n", 1)
verification = sections[1] if len(sections) == 2 else ""
required = (
    "Root and external-directory Make gates passed",
    "package-check reached the explicit Chalice availability guard",
    "root-derivation mutation failed",
    "test-command mutation failed",
    "compile-command mutation failed",
    "checker-path mutation failed",
    "package-check-path mutation failed",
    "plan-evidence mutation failed",
    "documentation mutation failed",
)

if (
    statuses != ["status: completed"]
    or any(item not in verification for item in required)
    or re.search(r"\b(?:pending|todo|tbd|not run)\b", verification, re.IGNORECASE)
):
    raise SystemExit(
        "Location-independent Make plan must record completed status and actual verification."
    )
PY

if ! grep -Fq "Verified Chalice deployment package" "$VENDOR_CLEANUP_PLAN" ||
  ! grep -Fq "Hostile mutations" "$VENDOR_CLEANUP_PLAN"; then
  printf '%s\n' "Chalice vendor cleanup plan must record completed package and mutation evidence." >&2
  exit 1
fi

python - "$TOTAL_RETRIEVAL_CONTEXT_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
statuses = re.findall(r"^status: .+$", plan, flags=re.MULTILINE)
sections = plan.split("## Verification Completed\n", 1)
verification = sections[1] if len(sections) == 2 else ""
required = (
    "focused aggregate-context test passed",
    "all API tests and every Make gate passed",
    "aggregate-budget removal mutation failed",
    "separator-accounting mutation failed",
    "regression-test removal mutation failed",
    "hosted pull-request and CodeQL snapshot",
)

if (
    statuses != ["status: completed"]
    or any(item not in verification for item in required)
    or re.search(r"\b(?:pending|todo|tbd|not run)\b", verification, re.IGNORECASE)
):
    raise SystemExit(
        "Total retrieval-context plan must record completed status and actual verification."
    )
PY

python - "$GRACEFUL_CACHE_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
statuses = re.findall(r"^status: .+$", plan, flags=re.MULTILINE)
sections = plan.split("## Verification Completed\n", 1)
verification = sections[1] if len(sections) == 2 else ""
required = (
    "focused cache-degradation tests passed",
    "All 46 API tests and every Make gate passed",
    "cache-read bypass removal mutation failed",
    "cache-write isolation removal mutation failed",
    "read-regression removal mutation failed",
    "write-regression removal mutation failed",
    "hosted pull-request and CodeQL snapshot",
)

if (
    statuses != ["status: completed"]
    or any(item not in verification for item in required)
    or re.search(r"\b(?:pending|todo|tbd|not run)\b", verification, re.IGNORECASE)
):
    raise SystemExit(
        "Graceful cache-bypass plan must record completed status and actual verification."
    )
PY

python - "$CACHE_RESPONSE_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
statuses = re.findall(r"^status: .+$", plan, flags=re.MULTILINE)
sections = plan.split("## Verification Completed\n", 1)
verification = sections[1] if len(sections) == 2 else ""
required = (
    "focused malformed-cache and cached-citation tests passed",
    "All 44 API tests and every Make gate passed",
    "Cache payload-validation removal failed",
    "Cached-link filtering removal failed",
    "Regression-test removal failed",
    "hosted pull-request and CodeQL snapshot",
)

if (
    statuses != ["status: completed"]
    or any(item not in verification for item in required)
    or re.search(r"\b(?:pending|todo|tbd|not run)\b", verification, re.IGNORECASE)
):
    raise SystemExit(
        "Cached-response plan must record completed status and actual verification."
    )
PY

python - "$VERCEL_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
frontmatter_parts = plan.split("---", 2)
frontmatter = frontmatter_parts[1] if len(frontmatter_parts) == 3 else ""
statuses = re.findall(r"^status: .+$", frontmatter, flags=re.MULTILINE)
sections = plan.split("## Verification Completed\n", 1)
verification = sections[1] if len(sections) == 2 else ""
required = (
    "`make verify`, all 41 API tests",
    "push run `27395011365`",
    "pull-request run `27395017871`",
    "Mutations enabling deployments globally",
    "no claim is made that",
)

if (
    statuses != ["status: completed"]
    or any(item not in verification for item in required)
    or re.search(r"\b(?:pending|todo|tbd|not run)\b", verification, re.IGNORECASE)
):
    raise SystemExit(
        "Vercel deployment-ownership plan must remain completed with actual verification recorded."
    )
PY

if ! grep -Fq "Mutations restoring raw query strings" "$CACHE_KEY_PLAN"; then
  printf '%s\n' "Cache query-key plan must record completed mutation verification." >&2
  exit 1
fi

if ! grep -Fq "Mutations accepting expired entries or omitting written TTLs must fail" "$CACHE_EXPIRATION_PLAN"; then
  printf '%s\n' "Cache expiration plan must record completed mutation verification." >&2
  exit 1
fi

if ! grep -Fq "DynamoDB response caching best-effort" "$ROOT_DIR/AGENTS.md" ||
  ! grep -Fq "Cache availability is not required for fresh answers" "$README" ||
  ! grep -Fq "DynamoDB response caching is best-effort" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "Keep cache backend failures from blocking fresh or already generated answers" "$VISION" ||
  ! grep -Fq "Made DynamoDB response caching best-effort" "$CHANGES"; then
  printf '%s\n' "Project guidance must document graceful cache degradation." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$CI_PLAN" ||
  ! grep -Fq "make check" "$CI_PLAN"; then
  printf '%s\n' "CI baseline plan must record hosted make check verification." >&2
  exit 1
fi

python3 - "$DEPENDENCY_LOCK_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
statuses = re.findall(r"^status: .+$", plan, flags=re.MULTILINE)
verification = plan.split("## Verification Completed\n", 1)[-1]
required = (
    "47 exact, hash-addressed packages",
    "Python 3.10 hash-required install passed",
    "temporary Chalice package gate passed",
    "Ten hostile mutations failed",
    "No live AWS, OpenAI, Pinecone, Twilio, or API Gateway operations were executed",
)
if (
    statuses != ["status: completed"]
    or "## Verification Completed\n" not in plan
    or any(item not in verification for item in required)
):
    raise SystemExit("Hashed dependency-lock plan must record completed verification.")
PY

python3 - "$BINARY_ARTIFACT_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
frontmatter = plan.split("---", 2)[1]
statuses = re.findall(r"^status: .+$", frontmatter, flags=re.MULTILINE)
required = (
    "clean Python 3.10 binary-only install passed",
    "repository and external-directory `make check` passed",
    "credential-free Chalice package gate passed",
    "Six hostile mutations failed",
    "No live AWS, OpenAI, Pinecone, Twilio, or API Gateway operations were executed",
)
if statuses != ["status: completed"] or any(item not in plan for item in required):
    raise SystemExit(
        "Binary-only dependency artifact plan must record completed verification."
    )
PY

if ! grep -Fq "hash-addressed Python 3.10 dependency lock" "$README" ||
  ! grep -Fq "Chalice deployment dependencies use hash-required deployment dependency" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "Keep deployment dependencies exact and hash-addressed" "$VISION" ||
  ! grep -Fq "Added a generated, hash-addressed Python 3.10 deployment dependency lock" "$CHANGES" ||
  ! grep -Fq "Regenerate the hash-addressed Python 3.10 deployment lock" "$ROOT_DIR/AGENTS.md"; then
  printf '%s\n' "Project guidance must document the hashed dependency lock." >&2
  exit 1
fi

if ! grep -Fq "binary wheels only" "$README" ||
  ! grep -Fq "binary-only installation" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "binary deployment artifacts" "$VISION" ||
  ! grep -Fq "Required binary-only dependency artifacts" "$CHANGES" ||
  ! grep -Fq -- "--only-binary=:all:" "$ROOT_DIR/AGENTS.md"; then
  printf '%s\n' "Project guidance must document binary-only dependency resolution." >&2
  exit 1
fi

if ! grep -Fq "Malformed retrieval matches containers" "$README" ||
  ! grep -Fq "Malformed retrieval matches containers" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "Malformed retrieval matches containers" "$VISION" ||
  ! grep -Fq "Malformed retrieval matches containers" "$ROOT_DIR/AGENTS.md" ||
  ! grep -Fq "Normalized malformed retrieval matches containers" "$CHANGES"; then
  printf '%s\n' "Project guidance must document retrieval matches-container normalization." >&2
  exit 1
fi

if ! grep -Fq "Unusable retrieval response accessors normalize to no matches" "$README" ||
  ! grep -Fq "Unusable retrieval response accessors must normalize to no matches" "$ROOT_DIR/SECURITY.md" ||
  ! grep -Fq "Unusable retrieval response accessors normalize to no matches" "$VISION" ||
  ! grep -Fq "Unusable retrieval response accessors must normalize to no matches" "$ROOT_DIR/AGENTS.md" ||
  ! grep -Fq "Normalized non-callable or failing retrieval response accessors" "$CHANGES"; then
  printf '%s\n' "Project guidance must document retrieval response accessor normalization." >&2
  exit 1
fi

python3 - "$RETRIEVAL_MATCHES_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
statuses = re.findall(r"^status: .+$", plan, flags=re.MULTILINE)
verification = plan.split("## Verification Completed\n", 1)[-1]
required = (
    "focused retrieval tests and complete API suite passed",
    "All four Make gates passed",
    "external-directory Make gate passed",
    "container-guard mutation failed",
    "mapping-acceptance mutation failed",
    "focused-test contract mutation failed",
    "plan-status mutation failed",
    "plan-evidence mutation failed",
)
if (
    statuses != ["status: completed"]
    or "## Verification Completed\n" not in plan
    or any(item not in verification for item in required)
    or re.search(r"\b(?:pending|todo|tbd|not run|not yet)\b", verification, re.IGNORECASE)
):
    raise SystemExit(
        "Retrieval matches-container plan must record completed verification."
    )
PY

python3 - "$RETRIEVAL_ACCESSOR_PLAN" <<'PY'
import re
import sys
from pathlib import Path

plan = Path(sys.argv[1]).read_text(encoding="utf-8")
statuses = re.findall(r"^status: .+$", plan, flags=re.MULTILINE)
verification = plan.split("## Verification Completed\n", 1)[-1]
normalized = " ".join(verification.split())
required = (
    "complete API suite passed with 50 tests",
    "All four Make gates passed",
    "external-directory Make gate passed",
    "Six isolated mutations were rejected",
    "no actionable findings or testing gaps",
    "Both canonical implementation-head checks passed",
    "push run 27646936359",
    "pull-request run 27646948344",
    "zero open alerts",
    "No live OpenAI, Pinecone, DynamoDB, AWS, Twilio, API Gateway, or deployment operation was executed",
)
if (
    statuses != ["status: completed"]
    or "## Verification Completed\n" not in plan
    or any(item not in normalized for item in required)
    or re.search(r"\b(?:pending|todo|tbd|not run|not yet)\b", verification, re.IGNORECASE)
):
    raise SystemExit(
        "Retrieval response accessor plan must record completed verification."
    )
PY
PYTHONPATH="$ROOT_DIR/api" python -m unittest discover -s "$ROOT_DIR/api/tests"
python -m compileall -q "$ROOT_DIR/api/app.py" "$ROOT_DIR/api/chalicelib" "$ROOT_DIR/api/tests"
"$EXTENSION_RENDERING_CHECK"

printf '%s\n' "GPT Docs API baseline checks passed."
