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
# FAIL-CLOSED policy:
#   When the guard cannot evaluate the policy (python3 missing, malformed
#   stdin JSON), the request is DENIED — not silently allowed. Users can
#   recover by installing python3 or by setting the opt-out env var.
#
# Categories in the policy file:
#   - always_block      → permissionDecision="deny"   (highest priority)
#   - ask_before_read   → permissionDecision="ask"    (user prompt)
#   - exempt_suffixes   → if basename ends with any, allow regardless
#
# Pattern syntax: fnmatch glob (`*`, `?`, `[seq]`). Matched against the
# *basename* (last `/`-segment) of file paths or Bash command tokens.

set -u

# ---- Helper: emit a hand-crafted deny JSON when python3 is unavailable.
emit_failsafe_deny() {
  local reason="$1"
  # Hand-craft minimal JSON; cannot rely on python3 here.
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$reason"
  echo "[project-lifecycle/secret-guard] DENY (fail-closed): $reason" >&2
  echo "  복구: python3 설치, 또는 일시 해제 CLAUDE_PLUGIN_SECRET_GUARD=off" >&2
  exit 2
}

# ---- 1. Opt-out check ---------------------------------------------------
case "${CLAUDE_PLUGIN_SECRET_GUARD:-on}" in
  off|0|false|FALSE|False)
    echo "[project-lifecycle/secret-guard] disabled via CLAUDE_PLUGIN_SECRET_GUARD" >&2
    exit 0
    ;;
esac

# ---- 2. python3 availability (FAIL-CLOSED) ----------------------------
if ! command -v python3 >/dev/null 2>&1; then
  emit_failsafe_deny "secret-guard 실행에 필요한 python3 가 없어 정책 평가 불가 — fail-closed 정책에 따라 차단"
fi

# ---- 3. Read tool call JSON from stdin --------------------------------
TOOL_JSON="$(cat)"

if [ -z "$TOOL_JSON" ]; then
  emit_failsafe_deny "stdin tool-call JSON 이 비어 있어 정책 평가 불가 — fail-closed"
fi

# ---- 4. Delegate decision to python3 ----------------------------------
SECRET_GUARD_TOOL_JSON="$TOOL_JSON" python3 <<'PY'
import sys, json, os, fnmatch, re

DEFAULTS = {
    "schema_version": 1,
    "always_block": [".env", ".env.*"],
    "ask_before_read": [],
    "exempt_suffixes": [".example", ".sample", ".template", ".dist"],
}

SUPPORTED_SCHEMA_VERSIONS = {1}

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


def emit_failclosed_deny_and_exit(reason):
    """Fail-closed: deny + hand-crafted JSON + exit 2."""
    out = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"fail-closed: {reason}",
        }
    }
    sys.stdout.write(json.dumps(out, ensure_ascii=False))
    sys.stdout.flush()
    sys.stderr.write(f"[project-lifecycle/secret-guard] DENY (fail-closed): {reason}\n")
    sys.stderr.write("  복구: 정책 파일 수정, 또는 일시 해제 CLAUDE_PLUGIN_SECRET_GUARD=off\n")
    sys.exit(2)


raw = os.environ.get("SECRET_GUARD_TOOL_JSON", "")
try:
    tool = json.loads(raw)
except Exception as exc:
    emit_failclosed_deny_and_exit(f"stdin JSON 파싱 실패: {exc}")

if not isinstance(tool, dict):
    emit_failclosed_deny_and_exit("stdin JSON 이 객체가 아님")

tool_name = tool.get("tool_name") or ""
tool_input = tool.get("tool_input") or {}
cwd = tool.get("cwd") or os.getcwd()


def coerce_string_list(value, field_name):
    """Validate value is a list of strings (or a single string).
    Returns (normalized_list, error_msg_or_None)."""
    if isinstance(value, str):
        return ([value], None)
    if not isinstance(value, list):
        return (None, f"{field_name} must be a list of strings (got {type(value).__name__})")
    out = []
    for i, item in enumerate(value):
        if not isinstance(item, str):
            return (
                None,
                f"{field_name}[{i}] must be string (got {type(item).__name__})",
            )
        out.append(item)
    return (out, None)


# Load policy (cwd/.claude/secret-guard.json) or fall back to defaults
policy = dict(DEFAULTS)
policy_path = os.path.join(cwd, ".claude", "secret-guard.json")
if os.path.exists(policy_path):
    try:
        with open(policy_path, "r", encoding="utf-8") as fp:
            user = json.load(fp)
        if not isinstance(user, dict):
            raise ValueError("policy root must be an object")

        sv = user.get("schema_version", 1)
        if not isinstance(sv, int) or sv not in SUPPORTED_SCHEMA_VERSIONS:
            # Unsupported schema → discard the entire user policy and fall back
            # to built-in defaults (the user-provided field shapes may not even
            # be valid for this schema). Safe by construction.
            sys.stderr.write(
                f"[project-lifecycle/secret-guard] {policy_path}: unsupported schema_version "
                f"({sv!r}) — 정책 전체를 내장 기본값으로 폴백\n"
            )
            # policy already == dict(DEFAULTS); skip per-field processing
        else:
            policy["schema_version"] = sv
            for field in ("always_block", "ask_before_read", "exempt_suffixes"):
                if field not in user:
                    continue
                normalized, err = coerce_string_list(user[field], field)
                if err is not None:
                    sys.stderr.write(
                        f"[project-lifecycle/secret-guard] {policy_path}: {err} — 해당 필드는 내장 기본값 적용\n"
                    )
                    # leave policy[field] = DEFAULTS[field]
                else:
                    policy[field] = normalized
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

# ---- Extract candidate basenames from the tool call ----
# Bash tokens are split aggressively to neutralize embedded shell separators
# like `;`, `|`, `&`, redirections, parentheses, equals, and commas.
SEPARATOR_RE = re.compile(r"[^<>|&;()=,\s\"']+")

candidates = []
if tool_name in ("Read", "Edit", "Write"):
    fp = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if fp:
        candidates.append(basename(fp))
elif tool_name == "Bash":
    cmd = tool_input.get("command") or ""
    # Walk every word fragment delimited by shell metacharacters. This catches
    # `cat .env;rm`, `cat .env|tee /tmp/x`, `KEY=$(cat .env)`, etc.
    for piece in SEPARATOR_RE.findall(cmd):
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
