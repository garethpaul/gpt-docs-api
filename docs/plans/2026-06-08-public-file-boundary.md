---
title: GPT Docs API Public File Boundary
type: fix
status: completed
date: 2026-06-08
---

# GPT Docs API Public File Boundary

## Summary

Keep unauthenticated public asset serving while preventing path traversal and
returning clear client errors for missing files.

## Requirements

- R1. `/public/{filename}` must resolve requested files inside
  `api/chalicelib/public`.
- R2. Path traversal attempts must return 400 without reading files outside the
  public directory.
- R3. Missing public files must return 404 rather than being caught as generic
  500 errors.
- R4. Known public files must keep returning bytes with an appropriate content
  type.
- R5. The source baseline guard must require the helper and route tests.

## Implementation

- Added `safe_public_file_path` to canonicalize public file paths and reject
  requests outside the public root.
- Added `public_content_type` for extension-based content type lookup with a
  safe binary fallback.
- Updated `serve_public` to return 400, 404, and 500 responses for distinct
  failure classes.
- Added fake-Chalice tests for serving `test.html`, missing files, and
  traversal attempts.

## Verification

- `make verify`
- `git diff --check`
