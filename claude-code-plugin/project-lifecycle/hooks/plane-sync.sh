#!/usr/bin/env bash
# project-lifecycle plugin — PostToolUse Plane integration push (v0.10.0)
#
# When `<project-root>/.claude/integrations.json` activates the Plane provider
# and the touched file matches a domain (issues / lifecycle / tech_debt /
# execution_plans), push the local change to Plane via REST.
#
# Charter: docs/direction/2026-04-30-plane-integration-charter.md
#
# Behavior:
#   - Acts only inside a git repository (graceful skip otherwise).
#   - Reads PostToolUse event JSON from stdin (Claude Code contract).
#   - **Fail-open**: any failure (token missing, network down, 5xx, parse
#     error) logs to stderr and exits 0. Never blocks the user's tool call.
#   - When integrations.json is absent or `tracker.primary` is null/local,
#     the script exits within microseconds — v0.9.0 bit-identical path.
#
# Opt-out (per session):
#   CLAUDE_PLUGIN_PLANE_SYNC=off|0|false|no  (case-insensitive)

set -u

# ---- 1. Opt-out check (case-insensitive) -------------------------------
GUARD_VALUE="${CLAUDE_PLUGIN_PLANE_SYNC:-on}"
GUARD_VALUE_LC="$(printf '%s' "$GUARD_VALUE" | tr '[:upper:]' '[:lower:]')"
case "$GUARD_VALUE_LC" in
  off|0|false|no)
    exit 0
    ;;
esac

# ---- 2. python3 availability (fail-open: skip silently) --------------
if ! command -v python3 >/dev/null 2>&1; then
  echo "[project-lifecycle/plane] python3 미설치 — sync 비활성 (작업은 계속 가능)" >&2
  exit 0
fi

# ---- 3. Forward stdin to the Python module entry point ----------------
PLUGIN_LIB="${CLAUDE_PLUGIN_ROOT:-}/hooks/lib"
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ] || [ ! -d "$PLUGIN_LIB" ]; then
  exit 0
fi

PLANE_LIB_DIR="$PLUGIN_LIB" python3 - <<'PY'
import os, sys
sys.path.insert(0, os.environ["PLANE_LIB_DIR"])
try:
    from plane_sync import run_post_tool_use
except Exception as exc:
    sys.stderr.write(f"[project-lifecycle/plane] plane_sync import 실패 — sync 비활성: {exc}\n")
    sys.exit(0)
sys.exit(run_post_tool_use())
PY

exit 0
