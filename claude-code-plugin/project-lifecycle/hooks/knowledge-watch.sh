#!/usr/bin/env bash
# project-lifecycle plugin — SessionStart knowledge watcher
#
# Reports the registered knowledge index/3-doc set to the model and warns
# when any of the watched files have drifted from the sha256 captured in
# `.claude/local/knowledge-watch.json` at registration/last update time.
#
# Behavior:
#   - Acts only inside a git repository (uses `git rev-parse --show-toplevel`).
#   - Reads only — never modifies knowledge-watch.json or any project file.
#   - Stdout is consumed by Claude Code as additional context for the session.
#   - Stderr is shown to the user in the terminal.
#
# Knowledge registration & updates are user-driven (the `knowledge` skill).
# This hook only surfaces drift and asks the user to consider running /knowledge.
#
# Charter: docs/direction/2026-04-28-three-doc-set-charter.md (D7, D8, principle 6)
#   - Watch baseline (.claude/local/knowledge-watch.json) is sha256 + path only,
#     NOT a content mirror.
#   - Detection is alert-only — never auto-update.

set -eu

# Only act inside a git repository.
if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

cd "$ROOT"

WATCH_JSON=".claude/local/knowledge-watch.json"
INDEX_MD=".claude/knowledge/index.md"

if [ ! -f "$WATCH_JSON" ]; then
  if [ -f "$INDEX_MD" ]; then
    echo "[project-lifecycle] knowledge 인덱스는 있지만 변경 감지 베이스라인이 없습니다. /knowledge 로 갱신 모드 1회 실행을 권장합니다." >&2
  fi
  # Silent if neither exists — knowledge feature is opt-in.
  exit 0
fi

# JSON parsing + sha256 hashing requires python3. Fall back gracefully if absent.
if ! command -v python3 >/dev/null 2>&1; then
  echo "[project-lifecycle] knowledge-watch: python3 가 필요합니다 — 변경 감지를 건너뜁니다." >&2
  exit 0
fi

python3 - "$WATCH_JSON" <<'PY'
import sys, json, hashlib, pathlib

watch_path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(watch_path.read_text(encoding="utf-8"))
except Exception as exc:
    sys.stderr.write(f"[project-lifecycle] knowledge-watch.json 파싱 실패: {exc}\n")
    sys.exit(0)

watched = data.get("watched_files") or []
if not watched:
    sys.stderr.write("[project-lifecycle] knowledge-watch.json 에 watched_files 가 비어있습니다.\n")
    sys.exit(0)

index_present = False
changes = []
missing = []
for entry in watched:
    rel = entry.get("path")
    if not rel:
        continue
    fp = pathlib.Path(rel)
    if rel.endswith("index.md"):
        index_present = fp.exists()
    if not fp.exists():
        missing.append(rel)
        continue
    try:
        current = hashlib.sha256(fp.read_bytes()).hexdigest()
    except Exception as exc:
        changes.append((rel, f"read_error:{exc}"))
        continue
    if current != entry.get("sha256"):
        changes.append((rel, "modified"))

# Stdout is forwarded to the model as additional context.
print("[project-lifecycle] 등록된 사내 3종 문서(knowledge):")
print(f"  - 인덱스: .claude/knowledge/index.md  ({'존재' if index_present else '없음'})")
print(f"  - 등록 파일 수: {len(watched)}  /  변경: {len(changes)}  /  누락: {len(missing)}")

if changes or missing:
    print("")
    print("[project-lifecycle] 다음 knowledge 파일이 등록 시점과 달라졌습니다 — /knowledge 로 갱신 검토를 권장합니다(자동 갱신은 하지 않습니다):")
    for rel, status in changes:
        print(f"  - {rel} ({status})")
    for rel in missing:
        print(f"  - {rel} (missing)")
PY

exit 0
