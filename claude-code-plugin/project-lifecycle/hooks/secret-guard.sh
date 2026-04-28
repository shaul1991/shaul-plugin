#!/usr/bin/env bash
# project-lifecycle plugin — PreToolUse secret-file guardrail
#
# Blocks (or asks confirmation for) tool calls that touch sensitive files
# such as `.env` and `.env.*`. Applies UNCONDITIONALLY across every step
# and skill of the plugin (no per-skill bypass).
#
# Mechanism:
#   - Reads tool call JSON from stdin (Claude Code PreToolUse contract).
#   - Reads optional user policy from <cwd>/.claude/secret-guard.json.
#   - If absent, applies built-in defaults: block .env / .env.* with
#     template-suffix exemptions (.example, .sample, .template, .dist).
#   - Outputs `hookSpecificOutput.permissionDecision` JSON on stdout.
#   - Exits 2 for deny (defensive double-guard), 0 otherwise.
#
# Charter: docs/direction/2026-04-28-secret-file-guardrail-charter.md
#
# Opt-out (per session, intentional):
#   CLAUDE_PLUGIN_SECRET_GUARD=off (or 0/false) → bypass entirely + stderr alert.
#
# Categories in the policy file:
#   - always_block      → permissionDecision="deny"   (highest priority)
#   - ask_before_read   → permissionDecision="ask"    (user prompt)
#   - exempt_suffixes   → if basename ends with any, allow regardless
#
# Pattern syntax: fnmatch glob (`*`, `?`, `[seq]`). Matched against the
# *basename* (last `/`-segment) of file paths or Bash command tokens.

set -u

# ---- 1. Opt-out check ---------------------------------------------------
case "${CLAUDE_PLUGIN_SECRET_GUARD:-on}" in
  off|0|false|FALSE|False)
    echo "[project-lifecycle/secret-guard] disabled via CLAUDE_PLUGIN_SECRET_GUARD" >&2
    exit 0
    ;;
esac

# ---- 2. python3 availability -------------------------------------------
if ! command -v python3 >/dev/null 2>&1; then
  echo "[project-lifecycle/secret-guard] python3 가 필요합니다 — 본 보안 가드는 비활성 상태로 진행합니다. 정책 강제를 위해 python3 설치를 권장합니다." >&2
  exit 0
fi

# ---- 3. Read tool call JSON from stdin --------------------------------
TOOL_JSON="$(cat)"

# ---- 4. Delegate decision to python3 ----------------------------------
# Pass the tool JSON via env var so the heredoc stays clean (and stdin is free).
SECRET_GUARD_TOOL_JSON="$TOOL_JSON" python3 <<'PY'
import sys, json, os, fnmatch, shlex

DEFAULTS = {
    "schema_version": 1,
    "always_block": [".env", ".env.*"],
    "ask_before_read": [],
    "exempt_suffixes": [".example", ".sample", ".template", ".dist"],
}

def emit_and_exit(decision, category, basename):
    out = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": (
                f"matched policy category '{category}' on basename '{basename}'"
            ),
        }
    }
    sys.stdout.write(json.dumps(out, ensure_ascii=False))
    sys.stdout.flush()
    sys.stderr.write(
        f"[project-lifecycle/secret-guard] {decision.upper()}: {basename} ({category})\n"
    )
    if decision == "deny":
        sys.stderr.write(
            "  사유: 시크릿 노출 방지 (charter: 2026-04-28-secret-file-guardrail)\n"
            "  정책 파일: .claude/secret-guard.json (없으면 내장 기본값)\n"
            "  일시 해제: CLAUDE_PLUGIN_SECRET_GUARD=off\n"
        )
        sys.exit(2)
    sys.exit(0)

raw = os.environ.get("SECRET_GUARD_TOOL_JSON", "")
try:
    tool = json.loads(raw)
except Exception as exc:
    sys.stderr.write(f"[project-lifecycle/secret-guard] stdin JSON 파싱 실패: {exc} — 가드 통과 처리\n")
    sys.exit(0)

tool_name = tool.get("tool_name") or ""
tool_input = tool.get("tool_input") or {}
cwd = tool.get("cwd") or os.getcwd()

# Load policy (cwd/.claude/secret-guard.json) or fall back to defaults
policy = DEFAULTS
policy_path = os.path.join(cwd, ".claude", "secret-guard.json")
if os.path.exists(policy_path):
    try:
        with open(policy_path, "r", encoding="utf-8") as fp:
            user = json.load(fp)
        policy = {
            "schema_version": user.get("schema_version", 1),
            "always_block": list(user.get("always_block", DEFAULTS["always_block"])),
            "ask_before_read": list(user.get("ask_before_read", DEFAULTS["ask_before_read"])),
            "exempt_suffixes": list(user.get("exempt_suffixes", DEFAULTS["exempt_suffixes"])),
        }
    except Exception as exc:
        sys.stderr.write(
            f"[project-lifecycle/secret-guard] {policy_path} 파싱 실패 — 내장 기본값 적용: {exc}\n"
        )

always_block = policy["always_block"]
ask_list = policy["ask_before_read"]
exempt_suffixes = policy["exempt_suffixes"]

def basename(path):
    return os.path.basename(path.rstrip("/")) if path else ""

def is_exempt(name):
    return any(name.endswith(s) for s in exempt_suffixes if s)

def matches(name, patterns):
    return any(fnmatch.fnmatchcase(name, p) for p in patterns if p)

def evaluate(name):
    """Return (decision, category) or (None, None) for allow."""
    if not name:
        return (None, None)
    if is_exempt(name):
        return (None, None)
    if matches(name, always_block):
        return ("deny", "always_block")
    if matches(name, ask_list):
        return ("ask", "ask_before_read")
    return (None, None)

# Determine the set of basenames to evaluate
candidates = []
if tool_name in ("Read", "Edit", "Write"):
    fp = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if fp:
        candidates.append(basename(fp))
elif tool_name == "Bash":
    cmd = tool_input.get("command") or ""
    try:
        tokens = shlex.split(cmd, posix=True)
    except ValueError:
        tokens = cmd.split()
    for tok in tokens:
        for piece in tok.replace("=", " ").replace(",", " ").split():
            piece = piece.lstrip("<>|&;()")
            if piece:
                candidates.append(basename(piece))
else:
    sys.exit(0)

# Walk candidates: deny wins, then ask, then allow
rank = {"deny": 2, "ask": 1, None: 0}
worst = (None, None, None)
for name in candidates:
    decision, cat = evaluate(name)
    if rank[decision] > rank[worst[0]]:
        worst = (decision, cat, name)
        if decision == "deny":
            break

if worst[0] is None:
    sys.exit(0)

emit_and_exit(worst[0], worst[1], worst[2])
PY
