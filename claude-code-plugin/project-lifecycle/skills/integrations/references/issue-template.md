---
plane_id:
plane_sequence_id:
plane_state: Backlog
plane_labels: [from:claude]
plane_url:
sync_origin: local
last_synced_at:
last_synced_hash:
---

# (이슈 제목 — Plane 의 name 으로 push 됨)

## 설명

(여기서부터 본문이 Plane 의 description 으로 push 된다. 마크다운 그대로 보존.)

## 재현 절차

1. ...
2. ...

## 기대 동작

...

## 실제 동작

...

## 비고

- 라벨 변경: 위 `plane_labels` 를 직접 편집. 다음 PostToolUse 에 PATCH.
- 상태 변경: 위 `plane_state` 를 직접 편집 (예: `Backlog` → `Todo` → `Inprogress` → `Done`).
- frontmatter 의 `plane_id`, `plane_sequence_id`, `plane_url`, `last_synced_*` 는 첫 push 후 자동 채움 — 직접 편집하지 마라.
- 본문(`# 제목` 부터)은 사람이 자유롭게 편집. hash 변화가 감지되면 자동 PATCH.

> 이 템플릿은 `docs/issues/<slug>.md` 표준이다. `.claude/integrations.json` 의
> `providers.plane.domains.issues.path_glob` 와 일치한다.
> 헌장: `docs/direction/2026-04-30-plane-integration-charter.md`.
