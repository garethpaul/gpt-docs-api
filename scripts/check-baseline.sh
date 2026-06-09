#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAKEFILE="$ROOT_DIR/Makefile"
README="$ROOT_DIR/README.md"
VISION="$ROOT_DIR/VISION.md"
CHANGES="$ROOT_DIR/CHANGES.md"
REQUIREMENTS="$ROOT_DIR/api/requirements.txt"
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

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  "CHANGES.md" \
  "README.md" \
  "SECURITY.md" \
  "VISION.md" \
  "Makefile" \
  "api/requirements.txt" \
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
  "docs/plans/2026-06-09-request-query-validation.md" \
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

for target in "test:" "compile:" "check:" "verify: test compile check"; do
  if ! grep -Fq "$target" "$MAKEFILE"; then
    printf '%s\n' "Makefile must expose target: $target" >&2
    exit 1
  fi
done

for requirement in \
  "chalice==1.33.0" \
  "openai==0.28.1" \
  "pinecone-client[grpc]==2.2.4" \
  "boto3==1.43.18"; do
  if ! grep -Fq "$requirement" "$REQUIREMENTS"; then
    printf '%s\n' "api/requirements.txt must keep compatible pin: $requirement" >&2
    exit 1
  fi
done

if ! grep -Fq "GPT_DOCS_API_KEY_ENV = 'GPT_DOCS_API_KEY'" "$CONFIG" ||
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

if ! grep -Fq "test_ask_rejects_unauthenticated_callers_before_body_or_model_work" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_classify_rejects_unauthenticated_callers_before_body_or_model_work" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_serve_public_returns_known_asset_with_content_type" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_serve_public_returns_404_for_missing_asset" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_serve_public_rejects_path_traversal" "$TEST_APP_AUTH" ||
  ! grep -Fq "assert_not_called" "$TEST_APP_AUTH"; then
  printf '%s\n' "Route tests must cover auth short-circuiting and public-file safety." >&2
  exit 1
fi

if ! grep -Fq "def get_cache_table(resource=None)" "$CACHE" ||
  ! grep -Fq "def get_cached_response(query, table=None)" "$CACHE" ||
  ! grep -Fq "def store_in_cache(query, response, links, table=None)" "$CACHE"; then
  printf '%s\n' "Cache helpers must remain injectable for no-credential tests." >&2
  exit 1
fi

if ! grep -Fq "test_import_does_not_create_dynamodb_resource" "$TEST_CACHE"; then
  printf '%s\n' "Cache tests must cover import safety without DynamoDB resources." >&2
  exit 1
fi

if grep -Fq "from chalice" "$UTILS" || grep -Fq "BadRequestError" "$UTILS"; then
  printf '%s\n' "Pure request utility helpers must not import Chalice." >&2
  exit 1
fi

if ! grep -Fq "ValueError('Request body must be JSON')" "$UTILS" ||
  ! grep -Fq "json.JSONDecodeError" "$UTILS" ||
  ! grep -Fq "ValueError('Query must be a string')" "$UTILS" ||
  ! grep -Fq "query = query.strip()" "$UTILS"; then
  printf '%s\n' "Utility helpers must preserve request and JSON parsing errors." >&2
  exit 1
fi

if ! grep -Fq 'validate_request_payload({"query": "   "})' "$TEST_UTILS" ||
  ! grep -Fq "Query must be a string" "$TEST_UTILS"; then
  printf '%s\n' "Utility tests must cover whitespace and non-string queries." >&2
  exit 1
fi

if ! grep -Fq "openai_client=openai" "$CLASSIFICATION" ||
  ! grep -Fq "Failed to generate classification" "$CLASSIFICATION"; then
  printf '%s\n' "Classification helpers must keep injectable OpenAI clients and wrapped errors." >&2
  exit 1
fi

if ! grep -Fq "FakeOpenAI" "$TEST_CLASSIFICATION" ||
  ! grep -Fq "extract_json_object_returns_empty_dict_without_stdout" "$TEST_UTILS"; then
  printf '%s\n' "Tests must cover fake OpenAI clients and quiet JSON parse failures." >&2
  exit 1
fi

if ! grep -Fq "make verify" "$README" ||
  ! grep -Fq "CHANGES.md" "$README" ||
  ! grep -Fq "GPT_DOCS_API_KEY" "$README" ||
  ! grep -Fq "public asset routes" "$README" ||
  ! grep -Fq "OpenAI" "$README" ||
  ! grep -Fq "Pinecone" "$README"; then
  printf '%s\n' "README must document verification, changelog, and external service boundaries." >&2
  exit 1
fi

if ! grep -Fq "Run \`make verify\`" "$VISION" ||
  ! grep -Fq "GPT_DOCS_API_KEY" "$VISION" ||
  ! grep -Fq "public asset" "$VISION"; then
  printf '%s\n' "VISION.md must keep the make verify and API auth contribution rules visible." >&2
  exit 1
fi

if ! grep -Fq "source baseline guard" "$CHANGES" ||
  ! grep -Fq "shared API-key guard" "$CHANGES" ||
  ! grep -Fq "public file path" "$CHANGES" ||
  ! grep -Fq "query validation" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the source baseline and auth guards." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PLAN" ||
  ! grep -Fq "status: completed" "$CHECK_PLAN" ||
  ! grep -Fq "status: completed" "$AUTH_PLAN" ||
  ! grep -Fq "status: completed" "$PUBLIC_PLAN" ||
  ! grep -Fq "status: completed" "$QUERY_PLAN"; then
  printf '%s\n' "Plan documents must be marked completed." >&2
  exit 1
fi

PYTHONPATH="$ROOT_DIR/api" python -m unittest discover -s "$ROOT_DIR/api/tests"
python -m compileall -q "$ROOT_DIR/api/app.py" "$ROOT_DIR/api/chalicelib" "$ROOT_DIR/api/tests"

printf '%s\n' "GPT Docs API baseline checks passed."
