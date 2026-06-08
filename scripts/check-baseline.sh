#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAKEFILE="$ROOT_DIR/Makefile"
README="$ROOT_DIR/README.md"
VISION="$ROOT_DIR/VISION.md"
CHANGES="$ROOT_DIR/CHANGES.md"
REQUIREMENTS="$ROOT_DIR/api/requirements.txt"
CACHE="$ROOT_DIR/api/chalicelib/cache.py"
CLASSIFICATION="$ROOT_DIR/api/chalicelib/classification.py"
UTILS="$ROOT_DIR/api/chalicelib/utils.py"
TEST_CACHE="$ROOT_DIR/api/tests/test_cache.py"
TEST_CLASSIFICATION="$ROOT_DIR/api/tests/test_classification.py"
TEST_UTILS="$ROOT_DIR/api/tests/test_utils.py"
PLAN="$ROOT_DIR/docs/plans/2026-06-08-gpt-docs-api-testability-dependency-baseline.md"
CHECK_PLAN="$ROOT_DIR/docs/plans/2026-06-08-source-baseline-guard.md"

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
  "api/chalicelib/cache.py" \
  "api/chalicelib/classification.py" \
  "api/chalicelib/config.py" \
  "api/chalicelib/utils.py" \
  "api/tests/test_cache.py" \
  "api/tests/test_classification.py" \
  "api/tests/test_utils.py" \
  "docs/plans/2026-06-08-gpt-docs-api-testability-dependency-baseline.md" \
  "docs/plans/2026-06-08-source-baseline-guard.md" \
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
  ! grep -Fq "json.JSONDecodeError" "$UTILS"; then
  printf '%s\n' "Utility helpers must preserve request and JSON parsing errors." >&2
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
  ! grep -Fq "OpenAI" "$README" ||
  ! grep -Fq "Pinecone" "$README"; then
  printf '%s\n' "README must document verification, changelog, and external service boundaries." >&2
  exit 1
fi

if ! grep -Fq "Run \`make verify\`" "$VISION"; then
  printf '%s\n' "VISION.md must keep the make verify contribution rule visible." >&2
  exit 1
fi

if ! grep -Fq "source baseline guard" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the source baseline guard." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PLAN" ||
  ! grep -Fq "status: completed" "$CHECK_PLAN"; then
  printf '%s\n' "Plan documents must be marked completed." >&2
  exit 1
fi

PYTHONPATH="$ROOT_DIR/api" python -m unittest discover -s "$ROOT_DIR/api/tests"
python -m compileall -q "$ROOT_DIR/api/app.py" "$ROOT_DIR/api/chalicelib" "$ROOT_DIR/api/tests"

printf '%s\n' "GPT Docs API baseline checks passed."
