#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FILES="
$ROOT_DIR/chrome_extension/content.js
$ROOT_DIR/api/chalicelib/public/content.js
"

for file in $FILES; do
  if grep -Fq 'innerHTML' "$file"; then
    printf '%s\n' "$file must not render content with innerHTML." >&2
    exit 1
  fi

  if ! grep -Fq 'function setText(element, value)' "$file"; then
    printf '%s\n' "$file must centralize text rendering through setText." >&2
    exit 1
  fi

  if ! grep -Fq 'function safeHttpUrl(value)' "$file"; then
    printf '%s\n' "$file must validate source links before assigning href." >&2
    exit 1
  fi

  if ! grep -Fq 'rel", "noopener noreferrer"' "$file"; then
    printf '%s\n' "$file must protect external source links opened in a new tab." >&2
    exit 1
  fi
done

printf '%s\n' "GPT Docs extension rendering checks passed."
