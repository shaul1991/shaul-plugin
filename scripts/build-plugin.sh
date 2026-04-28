#!/usr/bin/env bash
# build-plugin.sh — Rebuild the project-lifecycle plugin archive from source.
#
# Single source of truth for producing claude-code-plugin/project-lifecycle.plugin.
# CI (.github/workflows/plugin-archive-check.yml) and human contributors must
# both go through this script so the committed archive cannot drift from the
# source directory.
#
# Usage: bash scripts/build-plugin.sh
#
# Exits non-zero if the produced archive is missing required files or differs
# from the source tree.

set -euo pipefail

# Resolve repo root via git so the script works from any cwd.
ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

SRC_DIR="claude-code-plugin/project-lifecycle"
OUT_FILE="claude-code-plugin/project-lifecycle.plugin"

if [ ! -d "$SRC_DIR" ]; then
  echo "[build-plugin] source directory missing: $SRC_DIR" >&2
  exit 1
fi

# Required files inside the archive (paths relative to archive root).
REQUIRED=(
  ".claude-plugin/plugin.json"
  "hooks/hooks.json"
  "hooks/bootstrap-local.sh"
  "README.md"
)

# mktemp -u: get a unique path without creating the file (zip refuses to write
# into an existing non-zip file).
TMP_OUT=$(mktemp -u -t plugin-build.XXXXXX).zip
trap 'rm -f "$TMP_OUT"' EXIT

# Build the archive. We chdir into SRC_DIR so the archive root contains
# agents/, skills/, hooks/, .claude-plugin/, README.md (matches existing layout).
( cd "$SRC_DIR" && zip -rq "$TMP_OUT" . \
    -x ".DS_Store" \
    -x "*/.DS_Store" \
    -x "__MACOSX/*" \
    -x "*.swp" )

# Self-check 1: required entries present.
for f in "${REQUIRED[@]}"; do
  if ! unzip -l "$TMP_OUT" | awk '{print $4}' | grep -qxF "$f"; then
    echo "[build-plugin] required entry missing from archive: $f" >&2
    exit 2
  fi
done

# Self-check 2: archive contents byte-identical to source.
VERIFY_DIR=$(mktemp -d -t plugin-verify.XXXXXX)
trap 'rm -f "$TMP_OUT"; rm -rf "$VERIFY_DIR"' EXIT

( cd "$VERIFY_DIR" && unzip -oq "$TMP_OUT" )

if ! DIFF_OUT=$(diff -rq "$VERIFY_DIR" "$SRC_DIR" 2>&1); then
  echo "[build-plugin] archive differs from source:" >&2
  echo "$DIFF_OUT" >&2
  exit 3
fi

if [ -n "$DIFF_OUT" ]; then
  echo "[build-plugin] archive differs from source:" >&2
  echo "$DIFF_OUT" >&2
  exit 3
fi

# All checks passed — move the archive into place.
mv "$TMP_OUT" "$OUT_FILE"
trap - EXIT
rm -rf "$VERIFY_DIR"

# Report SHA256 + size for release-note bookkeeping.
SIZE=$(wc -c < "$OUT_FILE" | tr -d ' ')
if command -v sha256sum >/dev/null 2>&1; then
  SUM=$(sha256sum "$OUT_FILE" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  SUM=$(shasum -a 256 "$OUT_FILE" | awk '{print $1}')
else
  SUM="(no sha256 tool available)"
fi

echo "[build-plugin] built $OUT_FILE  size=${SIZE}B  sha256=${SUM}"
