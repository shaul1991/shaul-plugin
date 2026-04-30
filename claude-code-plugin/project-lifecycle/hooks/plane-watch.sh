#!/usr/bin/env bash
# project-lifecycle plugin — SessionStart Plane integration watch (v0.10.0)
#
# Read-only status report. Logs to stderr whether the Plane integration is
# active, which workspace/project, mode, and token source.
#
# Charter: docs/direction/2026-04-30-plane-integration-charter.md
#
# Behavior:
#   - Acts only inside a git repository (graceful skip otherwise).
#   - Never modifies any file. No HTTP calls (status report only).
#   - When integrations.json is absent or `tracker.primary` is null/local,
#     the script exits silently — v0.9.0 bit-identical path.

set -u

# ---- 1. Opt-out check (shared with plane-sync) -------------------------
GUARD_VALUE="${CLAUDE_PLUGIN_PLANE_SYNC:-on}"
GUARD_VALUE_LC="$(printf '%s' "$GUARD_VALUE" | tr '[:upper:]' '[:lower:]')"
case "$GUARD_VALUE_LC" in
  off|0|false|no)
    exit 0
    ;;
esac

# ---- 2. python3 availability (silent skip) ----------------------------
if ! command -v python3 >/dev/null 2>&1; then
  exit 0
fi

# ---- 3. Delegate to the Python module -------------------------------
PLUGIN_LIB="${CLAUDE_PLUGIN_ROOT:-}/hooks/lib"
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ] || [ ! -d "$PLUGIN_LIB" ]; then
  exit 0
fi

PLANE_LIB_DIR="$PLUGIN_LIB" python3 - <<'PY'
import os, sys
sys.path.insert(0, os.environ["PLANE_LIB_DIR"])
try:
    from plane_sync import run_session_start
except Exception as exc:
    sys.stderr.write(f"[project-lifecycle/plane] plane_sync import 실패: {exc}\n")
    sys.exit(0)
sys.exit(run_session_start())
PY

exit 0
