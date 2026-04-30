---
name: integrations
description: >
  외부 트래커(Plane Opensource 등) 연동 활성·점검·설명. "Plane 연동",
  "외부 트래커", "/integrations", "issue 동기화", "tracker integration",
  "integrations.json", "Plane API token", "self-host plane" 요청 시 사용.
  자동 push 동작은 PostToolUse 훅(plane-sync.sh)이 책임지며, 본 스킬은
  사용자가 *연동을 켜는 절차* 안내와 활성 상태 점검만 담당한다.
metadata:
  phase: "all"
  phase_name: "외부 트래커 연동 (옵션)"
---

# 외부 트래커 연동 (옵션)

shaul-plugin 의 4개 작업 자산(`docs/issues/`, `docs/alm/lifecycle.md`,
`docs/alm/tech-debt-registry.md`, `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md`)을
외부 트래커(v1: **Plane Opensource**)와 자동 동기화하는 옵션 통합.

> **헌장**: `docs/direction/2026-04-30-plane-integration-charter.md`
>
> **Default = local.** `.claude/integrations.json` 이 없거나 `tracker.primary` 가 `null` 이면
> 플러그인은 v0.9.0 동작과 비트단위 동일하게 작동한다. **본 스킬을 호출하지 않는 사용자에게는 영향 0.**

## 실행 절차

### Step 1: 현재 활성 상태 점검

세션 시작 시 `plane-watch.sh` 훅이 stderr 로 출력한다. 직접 확인하려면:

```bash
cat .claude/integrations.json 2>/dev/null || echo "(integrations.json 없음 — local 모드)"
ls -la .claude/local/plane.secret.json 2>/dev/null || echo "(토큰 파일 없음)"
echo "$CLAUDE_PLUGIN_PLANE_TOKEN $PLANE_API_TOKEN" | tr ' ' '\n' | grep -v '^$' || echo "(env 토큰 없음)"
```

**활성 조건 (모두 충족)**:
- `.claude/integrations.json` 존재 + `tracker.primary` = `"plane"`
- `providers.plane.workspace_slug`, `providers.plane.project_id` 모두 채워짐
- 토큰 1개 이상: `CLAUDE_PLUGIN_PLANE_TOKEN`, `PLANE_API_TOKEN`, 또는 `.claude/local/plane.secret.json`

### Step 2: Plane 준비 (사용자 작업)

Cloud / Self-host 둘 중 선택. 자세한 가이드는 `references/plane-quickstart.md` 참조.

- **Cloud**: https://plane.so/ → 회원가입 → Workspace + Project 생성 → Settings > API Tokens 에서 발급.
- **Self-host (권장 — 데이터 주권)**:
  ```bash
  git clone https://github.com/makeplane/plane plane-host
  cd plane-host
  docker compose -f docker-compose-hub.yml up -d
  # → http://localhost:80 에서 동일 절차
  ```

발급한 token, `workspace slug`, `project UUID` (Plane URL 의 `/projects/<uuid>/` 부분) 를 메모.

### Step 3: 설정 파일 작성 (사용자 직접)

플러그인은 자동으로 파일을 만들지 않는다 (헌장 D11). 사용자가 명시적으로 복사:

```bash
# 1) 비-시크릿 통합 설정
cp "${CLAUDE_PLUGIN_ROOT}/hooks/integrations-template.json" .claude/integrations.json

# 2) 시크릿 토큰 파일 (gitignore 차단 영역)
mkdir -p .claude/local
cp "${CLAUDE_PLUGIN_ROOT}/hooks/plane-secret-template.json" .claude/local/plane.secret.json
chmod 600 .claude/local/plane.secret.json
```

그리고 다음 4개 값을 사용자가 직접 편집:

| 파일 | 필드 | 채울 값 |
|------|------|---------|
| `.claude/integrations.json` | `providers.plane.workspace_slug` | Plane workspace slug |
| `.claude/integrations.json` | `providers.plane.project_id` | Plane Project UUID |
| `.claude/integrations.json` | `providers.plane.host` | Cloud=`https://api.plane.so` / Self-host=`https://your-host` |
| `.claude/local/plane.secret.json` | `api_token` | 발급한 API token |
| `.claude/local/plane.secret.json` | `issued_at` | 오늘 날짜 (ISO8601, UTC) — 90일 회전 알림용 |

### Step 4: 첫 세션 — DRY-RUN 권장

첫 활성 세션은 `safety.dry_run: true` 로 시작해 어떤 push 가 일어날지 stderr 로만 확인하고,
다음 세션부터 `false` 로 바꿔 실 push 를 켤 것을 권장한다 (헌장 D16, 유령 이슈 양산 회피).

```jsonc
"safety": {
  "dry_run": true   // 첫 세션
}
```

### Step 5: 동작 확인

- 세션 재시작 → stderr 에 `[project-lifecycle/plane] 활성: ...` 한 줄 출력 확인.
- `docs/issues/test-sync.md` 같은 시범 파일 1개 만들고 저장 → stderr 에 `PUSHED issue` 또는 `DRY-RUN ...` 확인.
- Plane UI 에서 새 Issue 가 생겼는지 확인 (실 push 모드일 때).
- 시범 파일에 자동 갱신된 frontmatter (`plane_id`, `last_synced_hash`) 확인.

### Step 6: 모드 선택

| 모드 | 의미 | 권장 상황 |
|------|------|-----------|
| `local` | 동기화 안 함 | 외부 협업 없음, 1인 개발 |
| `plane` | local → Plane push only. 의미상 Plane 마스터 | 팀이 Plane UI 에서 일상 트리아지 |
| `both` | push only, 충돌 시 local 우선 | 양쪽 다 자주 본다 |

> **v1 솔직한 한계**: `plane` 과 `both` 의 push 동작은 v1 에서 동일. 의미적 차이는 v0.11+ 의 pull 기능 슬롯이다.

## 트러블슈팅

| 증상 | 원인 / 조치 |
|------|-------------|
| stderr 에 활성 메시지 없음 | `.claude/integrations.json` 없음, `tracker.primary` ≠ `"plane"`, 토큰 부재 — Step 1 재점검 |
| `토큰 미설정 — sync 비활성` | env var 또는 secret 파일 1개 이상 필요. priority: `CLAUDE_PLUGIN_PLANE_TOKEN` > `PLANE_API_TOKEN` > 파일 |
| `401: ... — sync 비활성` | 토큰 만료/오타. `.claude/local/plane.secret.json` 의 `api_token` 갱신 또는 새 token 발급 |
| `429: ...` | rate limit. 1회 skip 후 자동 재시도 |
| `integrations.json 파싱 실패` | JSON 문법 오류. 사용자 작업은 *블록되지 않는다* (fail-open) — 고친 후 다음 PostToolUse 에 자동 재개 |
| frontmatter `plane_id` 실수 삭제 | 다음 push 시 *제목 검색* 으로 흡수 PATCH (중복 생성 방지). 안 잡히면 새 Issue CREATE 됨 |
| 임시 파일이 자동 push 되어 유령 이슈 발생 | `_drafts/` 같은 비-매칭 폴더에 두거나 path_glob 의 깊이 제한 활용 |

## 일시 비활성 (Opt-out)

세션 단위 일회성:

```bash
CLAUDE_PLUGIN_PLANE_SYNC=off claude
```

영구 비활성: `tracker.primary` 를 `null` 또는 `"local"` 로 변경.

## 가이드라인

- **자동 push 책임은 훅** (`plane-sync.sh`). 본 스킬·다른 어떤 스킬·에이전트도 외부 트래커에 *직접 쓰지 않는다* (헌장 D7).
- **별도 매핑 파일 만들지 않는다.** ID 매핑은 frontmatter 또는 file-end 주석 블록에 둔다 (헌장 D4).
- **토큰을 `.claude/integrations.json` 에 절대 박지 않는다.** git 추적 영역에 시크릿 X (헌장 D5).
- **다른 AI 도구 자동 동기화 X** — Plane 통합이 `.cursor/`, `.codex/`, `AGENTS.md` 자동 쓰기로 확장되지 않는다 (헌장 D10).

## 참고 자료

- **`references/plane-quickstart.md`** — Plane Cloud / Self-host 준비, token 발급, 첫 push 검증.
- **`references/issue-template.md`** — `docs/issues/<slug>.md` 표준 frontmatter + 본문 템플릿.
- **`references/integrations-template.json`** — `.claude/integrations.json` 시작 샘플 (hooks/ 사본과 동일).
- **헌장**: `docs/direction/2026-04-30-plane-integration-charter.md`.
- Plane API 명세: `https://developers.plane.so/`.
