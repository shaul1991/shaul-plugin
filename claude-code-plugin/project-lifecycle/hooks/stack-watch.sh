#!/usr/bin/env bash
# project-lifecycle plugin — SessionStart stack watcher
#
# Reports the registered tech stack of the user's project to the model and
# warns when watched manifests have drifted from the values captured in
# `.claude/local/stack.json`.
#
# Behavior:
#   - Acts only inside a git repository (uses `git rev-parse --show-toplevel`).
#   - Reads only — never modifies stack.json or any project file.
#   - Stdout is consumed by Claude Code as additional context for the session.
#   - Stderr is shown to the user in the terminal.
#
# Stack registration & updates are user-driven (the 03-architecture skill).
# This hook only surfaces what is already there and notes drift.

set -eu

# Only act inside a git repository.
if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

cd "$ROOT"

STACK_JSON=".claude/local/stack.json"

if [ ! -f "$STACK_JSON" ]; then
  echo "[project-lifecycle] 기술 스택이 아직 등록되지 않았습니다. /03-architecture 로 등록하세요." >&2
  exit 0
fi

# JSON parsing + sha256 hashing requires python3. Fall back gracefully if absent.
if ! command -v python3 >/dev/null 2>&1; then
  echo "[project-lifecycle] stack-watch: python3 가 필요합니다 — 변경 감지를 건너뜁니다." >&2
  exit 0
fi

python3 - "$STACK_JSON" <<'PY'
import sys, json, hashlib, pathlib

stack_path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(stack_path.read_text(encoding="utf-8"))
except Exception as exc:
    sys.stderr.write(f"[project-lifecycle] stack.json 파싱 실패: {exc}\n")
    sys.exit(0)

projects = data.get("projects") or []
if not projects:
    sys.stderr.write("[project-lifecycle] stack.json 에 등록된 프로젝트가 없습니다.\n")
    sys.exit(0)

summary_rows = []
changes = []
for proj in projects:
    pid = proj.get("id") or proj.get("path") or "?"
    path = proj.get("path") or "?"
    lang = proj.get("language") or "?"
    lang_v = proj.get("language_version") or ""
    fw = proj.get("framework") or "?"
    fw_v = proj.get("framework_version") or ""
    lang_str = f"{lang} {lang_v}".strip()
    fw_str = f"{fw} {fw_v}".strip()
    summary_rows.append(f"  - {pid}  ({path})  ::  {lang_str} + {fw_str}")

    for manifest in proj.get("watched_manifests") or []:
        rel = manifest.get("path")
        if not rel:
            continue
        mp = pathlib.Path(rel)
        if not mp.exists():
            changes.append((pid, rel, "missing"))
            continue
        try:
            current = hashlib.sha256(mp.read_bytes()).hexdigest()
        except Exception as exc:
            changes.append((pid, rel, f"read_error:{exc}"))
            continue
        if current != manifest.get("sha256"):
            changes.append((pid, rel, "modified"))

# Stdout is forwarded to the model as additional context for this session.
print("[project-lifecycle] 등록된 기술 스택:")
for row in summary_rows:
    print(row)

if changes:
    print("")
    print("[project-lifecycle] 다음 매니페스트가 등록 시점과 달라졌습니다 — /03-architecture 로 갱신 검토를 권장합니다:")
    for pid, rel, status in changes:
        print(f"  - {pid} :: {rel} ({status})")
PY

exit 0
