#!/usr/bin/env bash
# project-lifecycle plugin — SessionStart bootstrap
#
# Ensures the user's project has the local workspace where the governance
# skill saves per-branch execution plans, and that the plugin's entire
# `.claude/` output area is gitignored:
#
#   <project-root>/
#   ├── .gitignore                 ← must contain `.claude/`
#   └── .claude/                   ← entire folder ignored by default
#       └── local/plans/           ← created governance workspace
#
# Behavior:
#   - Acts only inside a git repository (uses `git rev-parse --show-toplevel`).
#   - Idempotent: safe to run on every SessionStart.
#   - Silent on success; only emits a one-line stderr message on first-time
#     setup or when upgrading a legacy `.claude/local/` line.

set -eu

# Only act inside a git repository to avoid creating folders in arbitrary cwds.
if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

cd "$ROOT"

CHANGED=0
UPGRADED=0

# 1) Create .claude/local/plans/ if missing.
if [ ! -d ".claude/local/plans" ]; then
  mkdir -p ".claude/local/plans"
  CHANGED=1
fi

GITIGNORE=".gitignore"
LINE=".claude/"

# Equivalence check for the canonical line `.claude/`.
has_new_pattern() {
  grep -qxF ".claude/"  "$GITIGNORE" 2>/dev/null \
    || grep -qxF ".claude"   "$GITIGNORE" 2>/dev/null \
    || grep -qxF ".claude/*" "$GITIGNORE" 2>/dev/null
}

# Equivalence check for the legacy `.claude/local/` line.
has_legacy_pattern() {
  grep -qxF ".claude/local/"  "$GITIGNORE" 2>/dev/null \
    || grep -qxF ".claude/local"   "$GITIGNORE" 2>/dev/null \
    || grep -qxF ".claude/local/*" "$GITIGNORE" 2>/dev/null
}

# 2) Upgrade legacy `.claude/local/` lines to `.claude/`.
#    - If only legacy is present: replace it in place with `.claude/`.
#    - If both legacy and new are present: delete the legacy line.
if [ -f "$GITIGNORE" ] && has_legacy_pattern; then
  TMP="$GITIGNORE.tmp.$$"
  if has_new_pattern; then
    # Both present — drop legacy lines.
    awk '
      $0 == ".claude/local/"  { next }
      $0 == ".claude/local"   { next }
      $0 == ".claude/local/*" { next }
      { print }
    ' "$GITIGNORE" > "$TMP"
  else
    # Only legacy present — rewrite first match to `.claude/`, drop subsequent legacy duplicates.
    awk '
      BEGIN { replaced = 0 }
      $0 == ".claude/local/" || $0 == ".claude/local" || $0 == ".claude/local/*" {
        if (replaced == 0) { print ".claude/"; replaced = 1 }
        next
      }
      { print }
    ' "$GITIGNORE" > "$TMP"
  fi
  mv "$TMP" "$GITIGNORE"
  UPGRADED=1
  CHANGED=1
fi

# 3) Ensure .gitignore contains `.claude/` (or an equivalent pattern).
if [ ! -f "$GITIGNORE" ]; then
  printf '%s\n' "$LINE" > "$GITIGNORE"
  CHANGED=1
elif ! has_new_pattern; then
  if [ -s "$GITIGNORE" ] && [ "$(tail -c1 "$GITIGNORE" | od -An -c | tr -d ' ')" != "\n" ]; then
    printf '\n' >> "$GITIGNORE"
  fi
  printf '%s\n' "$LINE" >> "$GITIGNORE"
  CHANGED=1
fi

if [ "$UPGRADED" -eq 1 ]; then
  echo "[project-lifecycle] upgraded .gitignore: '.claude/local/' -> '.claude/'" >&2
elif [ "$CHANGED" -eq 1 ]; then
  echo "[project-lifecycle] bootstrapped .claude/ (gitignored) and .claude/local/plans/" >&2
fi

exit 0
