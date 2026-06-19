#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
API_DIR="$ROOT_DIR/api"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/gpt-docs-api-package.XXXXXX")

cleanup() {
  rm -rf "$WORK_DIR"
}

PACKAGE_PID=

terminate() {
  signal=$1
  status=$2
  trap - HUP INT TERM

  if [ -n "$PACKAGE_PID" ] && kill -0 "$PACKAGE_PID" 2>/dev/null; then
    kill -s "$signal" "-$PACKAGE_PID" 2>/dev/null ||
      kill -s "$signal" "$PACKAGE_PID" 2>/dev/null || true
    sleep 1
    if kill -0 "$PACKAGE_PID" 2>/dev/null; then
      kill -KILL "-$PACKAGE_PID" 2>/dev/null ||
        kill -KILL "$PACKAGE_PID" 2>/dev/null || true
    fi
    wait "$PACKAGE_PID" 2>/dev/null || true
  fi

  exit "$status"
}

trap cleanup EXIT
trap 'terminate HUP 129' HUP
trap 'terminate INT 130' INT
trap 'terminate TERM 143' TERM

for command in chalice python timeout; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf '%s\n' "Required package verification command is unavailable: $command" >&2
    exit 1
  fi
done

PROJECT_DIR="$WORK_DIR/project"
OUTPUT_DIR="$WORK_DIR/output"
mkdir -p "$PROJECT_DIR/.chalice"
cp "$API_DIR/app.py" "$API_DIR/requirements.in" \
  "$API_DIR/requirements.txt" "$PROJECT_DIR/"
cp -R "$API_DIR/chalicelib" "$PROJECT_DIR/chalicelib"
cp "$API_DIR/iam-policy.json" \
  "$PROJECT_DIR/.chalice/policy-package-verification.json"
find "$PROJECT_DIR" -type d -name __pycache__ -prune -exec rm -rf {} +
find "$PROJECT_DIR" -type f \( -name '*.pyc' -o -name '*.pyo' \) -exec rm -f {} +

cat >"$PROJECT_DIR/.chalice/config.json" <<'JSON'
{
  "version": "2.0",
  "app_name": "gpt-docs-api-package-verification",
  "autogen_policy": false,
  "stages": {
    "package-verification": {
      "api_gateway_stage": "api"
    }
  }
}
JSON

(
  cd "$PROJECT_DIR"
  exec env \
    PYTHONPATH= \
    PYTHONNOUSERSITE=1 \
    PIP_REQUIRE_HASHES=1 \
    PIP_ONLY_BINARY=:all: \
    AWS_DEFAULT_REGION=us-east-1 \
    AWS_EC2_METADATA_DISABLED=true \
    AWS_CONFIG_FILE=/dev/null \
    AWS_SHARED_CREDENTIALS_FILE=/dev/null \
    AWS_ACCESS_KEY_ID=package-verification \
    AWS_SECRET_ACCESS_KEY=package-verification \
    AWS_SESSION_TOKEN=package-verification \
    timeout "${CHALICE_PACKAGE_TIMEOUT_SECONDS:-600}" chalice package \
      --stage package-verification "$OUTPUT_DIR"
) &
PACKAGE_PID=$!

if wait "$PACKAGE_PID"; then
  package_status=0
else
  package_status=$?
fi
PACKAGE_PID=

if [ "$package_status" -ne 0 ]; then
  exit "$package_status"
fi

ARCHIVE="$OUTPUT_DIR/deployment.zip"
SAM_TEMPLATE="$OUTPUT_DIR/sam.json"
if [ ! -f "$ARCHIVE" ] || [ ! -f "$SAM_TEMPLATE" ]; then
  printf '%s\n' "Chalice did not create deployment.zip and sam.json" >&2
  exit 1
fi

python - "$ARCHIVE" "$SAM_TEMPLATE" <<'PY'
import json
import sys
from zipfile import ZipFile

archive = sys.argv[1]
sam_template = sys.argv[2]
with ZipFile(archive) as package:
    entries = set(package.namelist())

with open(sam_template, encoding="utf-8") as template_file:
    template = json.load(template_file)

functions = [
    resource["Properties"]
    for resource in template["Resources"].values()
    if resource["Type"] == "AWS::Serverless::Function"
]
if not functions:
    raise SystemExit("SAM template does not contain a serverless function")
if any(function.get("Runtime") != "python3.10" for function in functions):
    raise SystemExit("SAM functions must target python3.10")
if any(function.get("CodeUri") != "./deployment.zip" for function in functions):
    raise SystemExit("SAM functions must reference deployment.zip")

roles = [
    resource["Properties"]
    for resource in template["Resources"].values()
    if resource["Type"] == "AWS::IAM::Role"
]
if len(roles) != 1:
    raise SystemExit("SAM template must contain one managed IAM role")

statements = {
    (
        statement.get("Effect"),
        tuple(sorted(statement.get("Action", []))),
        statement.get("Resource"),
    )
    for statement in roles[0]["Policies"][0]["PolicyDocument"]["Statement"]
}
expected_statements = {
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
if statements != expected_statements:
    raise SystemExit("SAM role must contain only scoped cache and log writes")

required_files = {
    "app.py",
    "chalicelib/auth.py",
    "chalicelib/cache.py",
    "chalicelib/classification.py",
    "chalicelib/config.py",
    "chalicelib/utils.py",
}
missing_files = sorted(required_files - entries)
if missing_files:
    raise SystemExit(f"deployment package is missing application files: {missing_files}")

required_packages = ("chalice/", "openai/", "pinecone/")
missing_packages = [
    prefix for prefix in required_packages if not any(name.startswith(prefix) for name in entries)
]
if missing_packages:
    raise SystemExit(f"deployment package is missing runtime dependencies: {missing_packages}")

forbidden = [
    name
    for name in entries
    if name.startswith(("api/vendor/", "api/tests/", ".chalice/", ".env"))
    or name in {"test_app_auth.py", "test_auth.py", "test_cache.py"}
]

if forbidden:
    raise SystemExit(
        "deployment package contains forbidden generated or test content: "
        + ", ".join(sorted(forbidden)[:20])
    )

print(
    f"Verified Chalice deployment package with {len(entries)} entries "
    f"and {len(functions)} Python 3.10 function with scoped cache access."
)
PY
