#!/usr/bin/env bash
# project-lifecycle plugin — SessionStart bootstrap
#
# Ensures the user's project has the local workspace where the governance
# skill saves per-branch execution plans:
#
#   <project-root>/
#   ├── .gitignore                 ← must contain `.claude/local/`
#   └── .claude/local/plans/       ← created (gitignored) workspace
#
# Behavior:
#   - Acts only inside a git repository (uses `git rev-parse --show-toplevel`).
#   - Idempotent: safe to run on every SessionStart.
#   - Silent on success; only emits a one-line stderr message on first-time setup.

set -eu

# Only act inside a git repository to avoid creating folders in arbitrary cwds.
if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

cd "$ROOT"

CHANGED=0

# 1) Create .claude/local/plans/ if missing.
if [ ! -d ".claude/local/plans" ]; then
  mkdir -p ".claude/local/plans"
  CHANGED=1
fi

# 2) Ensure .gitignore contains `.claude/local/` (or an equivalent pattern).
GITIGNORE=".gitignore"
LINE=".claude/local/"

has_pattern() {
  # Accept any of these as already-present:
  #   .claude/local/      (canonical)
  #   .claude/local       (no trailing slash)
  #   .claude/local/*     (glob form)
  grep -qxF ".claude/local/" "$GITIGNORE" 2>/dev/null \
    || grep -qxF ".claude/local"  "$GITIGNORE" 2>/dev/null \
    || grep -qxF ".claude/local/*" "$GITIGNORE" 2>/dev/null
}

if [ ! -f "$GITIGNORE" ]; then
  printf '%s\n' "$LINE" > "$GITIGNORE"
  CHANGED=1
elif ! has_pattern; then
  # Append with a leading newline if the file does not end with one.
  if [ -s "$GITIGNORE" ] && [ "$(tail -c1 "$GITIGNORE" | od -An -c | tr -d ' ')" != "\n" ]; then
    printf '\n' >> "$GITIGNORE"
  fi
  printf '%s\n' "$LINE" >> "$GITIGNORE"
  CHANGED=1
fi

if [ "$CHANGED" -eq 1 ]; then
  echo "[project-lifecycle] bootstrapped .claude/local/plans/ and .gitignore" >&2
fi

exit 0
