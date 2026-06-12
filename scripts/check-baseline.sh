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
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

for target in "lint:" "test:" "build: compile" "compile:" "check:" "verify: test compile check"; do
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

if ! grep -Fq "workflow_dispatch:" "$CI_WORKFLOW" ||
  ! grep -Fq "contents: read" "$CI_WORKFLOW" ||
  ! grep -Fq "cancel-in-progress: true" "$CI_WORKFLOW" ||
  ! grep -Fq "runs-on: ubuntu-24.04" "$CI_WORKFLOW" ||
  ! grep -Fq "timeout-minutes: 15" "$CI_WORKFLOW" ||
  ! grep -Fq "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" "$CI_WORKFLOW" ||
  ! grep -Fq "actions/setup-python@a309ff8b426b58ec0e2a45f0f869d46889d02405" "$CI_WORKFLOW" ||
  ! grep -Fq 'python-version: "3.10"' "$CI_WORKFLOW" ||
  ! grep -Fq "api/requirements.txt" "$CI_WORKFLOW" ||
  ! grep -Fq "python -m pip check" "$CI_WORKFLOW" ||
  ! grep -Fq "make check" "$CI_WORKFLOW"; then
  printf '%s\n' "GitHub Actions must keep the pinned Python 3.10 dependency and test contract." >&2
  exit 1
fi

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
  ! grep -Fq "sorted({url for url in urls if is_twilio_doc_url(url)})" "$APP"; then
  printf '%s\n' "Generated answer links must be filtered by HTTPS Twilio host." >&2
  exit 1
fi

if ! grep -Fq "def metadata_text_and_url(item)" "$APP" ||
  ! grep -Fq "isinstance(metadata, dict)" "$APP" ||
  ! grep -Fq "isinstance(text, str)" "$APP" ||
  ! grep -Fq "MAX_RETRIEVAL_CONTEXT_LENGTH = 4000" "$APP" ||
  ! grep -Fq "context[:MAX_RETRIEVAL_CONTEXT_LENGTH]" "$APP" ||
  ! grep -Fq "res.get('matches', [])" "$APP" ||
  ! grep -Fq "metadata_text_and_url(item)" "$APP"; then
  printf '%s\n' "Retrieval metadata must be validated before answer generation." >&2
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
  ! grep -Fq "test_make_query_skips_incomplete_metadata" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_make_query_truncates_overlong_metadata_text" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_ask_returns_generic_error_for_unexpected_failures" "$TEST_APP_AUTH" ||
  ! grep -Fq "test_classify_returns_generic_error_for_unexpected_failures" "$TEST_APP_AUTH" ||
  ! grep -Fq "assert_not_called" "$TEST_APP_AUTH"; then
  printf '%s\n' "Route tests must cover auth short-circuiting and public-file safety." >&2
  exit 1
fi

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
  ! grep -Fq "expires_at" "$README" ||
  ! grep -Fq "fixed-size SHA-256 identity" "$README" ||
  ! grep -Fq "generic 500 errors" "$README" ||
  ! grep -Fq "classification weight schema" "$README" ||
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
  ! grep -Fq "cache expiration" "$VISION" ||
  ! grep -Fq "fixed-size SHA-256 cache keys" "$VISION" ||
  ! grep -Fq "generic 500 errors" "$VISION" ||
  ! grep -Fq "classification weight schema" "$VISION"; then
  printf '%s\n' "VISION.md must keep the make verify and API auth contribution rules visible." >&2
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
  ! grep -Fq "cache entries" "$CHANGES" ||
  ! grep -Fq "SHA-256 identities" "$CHANGES" ||
  ! grep -Fq "generic 500 errors" "$CHANGES" ||
  ! grep -Fq "classification weight schema" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the source baseline and auth guards." >&2
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
  ! grep -Fq "status: completed" "$ROOT_DIR/docs/plans/2026-06-09-twilio-link-host-filtering.md"; then
  printf '%s\n' "Plan documents must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "Mutations restoring raw query strings" "$CACHE_KEY_PLAN"; then
  printf '%s\n' "Cache query-key plan must record completed mutation verification." >&2
  exit 1
fi

if ! grep -Fq "Mutations accepting expired entries or omitting written TTLs must fail" "$CACHE_EXPIRATION_PLAN"; then
  printf '%s\n' "Cache expiration plan must record completed mutation verification." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$CI_PLAN" ||
  ! grep -Fq "make check" "$CI_PLAN"; then
  printf '%s\n' "CI baseline plan must record hosted make check verification." >&2
  exit 1
fi

PYTHONPATH="$ROOT_DIR/api" python -m unittest discover -s "$ROOT_DIR/api/tests"
python -m compileall -q "$ROOT_DIR/api/app.py" "$ROOT_DIR/api/chalicelib" "$ROOT_DIR/api/tests"

printf '%s\n' "GPT Docs API baseline checks passed."
