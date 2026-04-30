# Plane Opensource 연동 헌장 (옵션 트래커 통합)

- **작성일**: 2026-04-30
- **반영 출시**: v0.10.0
- **관련 커밋**: (출시 시 추가)
- **상태**: Active
- **상위 헌장**: `2026-04-29-claude-as-settings-only-charter.md`(v0.9.0), `2026-04-28-secret-file-guardrail-charter.md`(v0.7.0), `2026-04-28-claude-output-charter.md`(v0.4.0)
- **참조 구현**: (출시 시 pkpk-api 적용 결과 추가)

## 사용자 원문 요구사항

세션 중 사용자가 보낸 메시지를 시간순으로 보존한다(의역·축약 최소화).

### (1) 초기 요구 — 외부 트래커 옵션 통합

> plane opensource와 연동하여 사용할 수 있도록 구성하려 한다.
> .claude/config.json 과 같은 느낌으로 설정을 관리 할 수 있는 파일을 하나 만들고,
> 활성화 여부에 따라서 plane/local(default)/both 등 사용할 수 있도록 하려 한다.
> 먼저 어떻게 구성할지 계획을 짜라.

### (2) 결정사항 (AskUserQuestion 답변)

- **연동 도메인**: `docs/issues/`, `docs/alm/lifecycle.md`, `docs/alm/tech-debt-registry.md`, `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md` (4개 모두)
- **설정 파일**: `.claude/integrations.json` (확장 가능 구조 — 미래 Linear/Jira 형제 키 추가)
- **API 토큰 위치**: `.claude/local/plane.secret.json`
- **호출 방식**: integrations.json 의 모드가 `plane` 또는 `both` 일 때 자동

## 도출한 원칙 (5개)

1. **옵션 통합, default 비트단위 동일.** 본 통합은 `.claude/integrations.json` 이 *없거나* `tracker.primary` 가 `null`/없음일 때 v0.9.0 동작과 *비트단위 동일*하게 작동한다. 기존 사용자 영향 0.
2. **외부 트래커는 동시 1개 (primary).** v0.10.0 에서 Plane / Linear / Jira 동시 활성은 비지원. `tracker.primary` 단일값. 형제 provider 키 추가는 *미래 옵션* 슬롯일 뿐 동시 동작 보장 X.
3. **v1 은 push only — 단방향.** local → 외부 트래커 push. pull(외부 → local 끼얹기) 은 *사용자 명시 명령* 으로만 v0.11+ 에서 도입. 자동 pull 없음. (`plane`/`both` 의미 분리는 pull 슬롯)
4. **자동 sync 는 훅 책임, 스킬·에이전트는 안내만.** stack-watch / knowledge-watch 패턴 계승 — 스킬이 외부 시스템에 *직접 쓰지 않는다*. dashboard 같은 read-only 분기는 예외.
5. **마크다운 본문 오염 최소화.** 매핑 메타데이터는 *frontmatter* 또는 *file-end HTML 주석 블록* 만 기계 사용. 사람이 읽는 표·문장에 메타 박지 않는다.

## 설계 결정

| ID | 결정 | 근거 |
|----|------|------|
| D1 | 통합은 *옵션*. default 모드 = `local` (= v0.9.0 비트단위 동일) | 사용자 요구 (1)·원칙 1. 기존 사용자 비파괴. |
| D2 | 트래커는 1순간에 *primary 1개*. 동시 다중 (Plane + Jira) v1 비지원 | 원칙 2. 충돌 의미·라우팅 복잡도. 형제 provider 키는 미래 슬롯. |
| D3 | v1 은 push only. pull 은 v0.11+ 사용자 명시 명령 한정. `plane`/`both` 의미적 분리는 pull 슬롯 | 원칙 3. 양방향 충돌 정책은 *사용자 결정 영역* — v1 자동화 X. |
| D4 | ID 매핑은 *frontmatter (A·D 도메인)* 또는 *file-end 주석 블록 (B·C 도메인)*. 별도 `plane.map.json` 금지 | 파일 mv/rename/삭제 시 자연 추적. git diff 가독성. 1파일 N entity (tech-debt) 흡수. |
| D5 | 토큰은 `.claude/local/plane.secret.json` + secret-guard `*.secret.json` 차단 | v0.7.0 헌장 D2·D5 계승 (정책 영역 .claude/, 차단은 가드가). 사본 X. |
| D6 | HTTP 실패는 *fail-open* (`safety.fail_open: true` default). 단 401 은 명확 메시지로 sync 비활성 | secret-guard fail-closed 와 대비 — *시크릿 노출* 비가역 위험 vs *sync 지연* 가역 위험. 오프라인 작업 보장. |
| D7 | 자동 push 는 PostToolUse 훅 책임. 스킬·에이전트는 *안내만* | 원칙 4. stack-watch / knowledge-watch 패턴 계승 — 자동 동작은 한 곳. |
| D8 | 마크다운 본문 오염 최소화 — frontmatter 와 file-end 주석만 기계 사용 | 원칙 5. GitHub UI/IDE 가독성. `local` 모드면 frontmatter 도 생성 X. |
| D9 | 도메인 매핑 변경은 본 헌장 갱신 후 반영 | 매핑 = 외부 시스템 데이터 모델 결정. 임의 변경 시 ID 재바인딩 폭발. |
| D10 | 다른 AI 도구 자동 동기화 금지 (claude-output-charter 직계승). Plane → `.cursor/`/`.codex/`/`AGENTS.md` 자동 쓰기 X | 모든 선행 헌장(v0.4.0/0.6.0/0.7.0/0.8.0/0.9.0)이 일관 계승. |
| D11 | 설정 파일 위치 = `.claude/integrations.json` (직속) | v0.9.0 헌장 D1: `.claude/` = Claude/플러그인이 자동 로드·평가하는 *사용 설정* 만. 본 파일은 훅이 자동 로드. |
| D12 | provider key 는 *미래 형제* — Linear/Jira 추가 시 `providers.<name>` 형제 키, `tracker.primary` 만 스위치 | 단일 파일 단일 source of truth. 키 충돌·스키마 분기 없음. |
| D13 | 토큰 우선순위: `CLAUDE_PLUGIN_PLANE_TOKEN` > `PLANE_API_TOKEN` > `plane.secret.json` > 없음(skip) | 환경변수 = 외부 시크릿 매니저(1Password CLI 등) hand-off 자연 지점. CI 임시 토큰 우선. |
| D14 | secret-guard 기본 차단 확장: `*.secret.json`, `plane.secret.json` 추가 | v0.7.0 헌장 D3·D7: 기본값 확장은 *본 헌장* 갱신 후만 — 본 헌장이 그 갱신. |
| D15 | 도메인별 모드 상속: 각 `domains.<x>.mode` 미지정 시 `tracker.default_mode` 상속 | 사용자 편의. 모든 도메인을 하나로 켜고 싶을 때 default_mode 한 줄. |
| D16 | safety.dry_run 은 *처음 1세션 자동 활성*, 다음 세션부터 사용자 명시 결정 | 자동 push 폭주(유령 이슈) 방지. 사용자가 다음 세션에 명시적으로 끄고 실 push. |

## 도메인 매핑

| # | 로컬 자산 | Plane entity | 매핑 저장 위치 | v1 |
|---|---|---|---|---|
| A | `docs/issues/<slug>.md` | Issue (root) | 파일 frontmatter | ✅ |
| B | `docs/alm/lifecycle.md` | Module "ALM Lifecycle" + Module 안 Issue per Phase | file-end `<!-- plane-sync:lifecycle ... -->` 주석 블록 | ⚠️ Module + Phase Issue 까지만 (표 row → 코멘트화는 future) |
| C | `docs/alm/tech-debt-registry.md` | Issue per `TD-NNN`, label=`tech-debt` + severity 라벨 | file-end `<!-- plane-sync:tech-debt ... -->` 주석 블록 | ✅ |
| D | `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md` | Sub-issue (parent = B 의 Phase Issue) | 파일 frontmatter | ✅ |

## 모드 동작

| 모드 | 동작 | source of truth | v1 |
|------|------|----------------|----|
| `local` (default) | Plane 호출 0회, v0.9.0 비트단위 동일 | local | ✅ |
| `plane` | local → Plane push only. 의미상 Plane 마스터, 충돌 시 Plane 우선 | Plane | push only ✅ / pull 🛇 |
| `both` | push only, 충돌 시 local 우선 (직접 편집 의도 존중) | local + Plane (eventual) | push only ✅ |

**v1 솔직한 한계**: 세 모드의 push 동작은 동일. `local` 만 push 안 함. `plane`/`both` 의미 분리는 v0.11 pull 기능 슬롯 (D3).

## 미래 변경 시 지킬 것

이 헌장은 후속 변경에 대한 **불변 가드레일**이다. 위반 시 본 문서를 먼저 갱신하거나(=원칙 변경의 근거 기록) 설계를 바꾼다.

1. **default = local 비트단위 동일.** `.claude/integrations.json` 부재 또는 `tracker.primary=null` 일 때 어떤 새 도메인·기능을 추가해도 v0.9.0 결과와 *동일*해야 한다. 새 훅을 추가할 때 이 가드를 *유닛 단위* 로 회귀 검증.
2. **동시 다중 트래커 도입 금지(v0.10.x).** `tracker.primary` 의 단일성. 다중 동시 활성은 별도 헌장 + 라우팅 정책 필요.
3. **자동 pull 도입 금지(v0.10.x).** pull 은 v0.11+ 의 *사용자 명시 명령* 으로만 도입. PostToolUse / SessionStart 자동 트리거에서 pull X.
4. **별도 매핑 파일(`plane.map.json` 등) 도입 금지.** 매핑은 frontmatter 또는 file-end 주석 블록. 사본 동기화 메커니즘 필요시 본 헌장 갱신 우선.
5. **시크릿 파일군 자동 부풀리기 금지(v0.7.0 헌장 D7 계승).** `*.secret.json` 외 새 시크릿 패턴 기본 차단 추가는 본 헌장 또는 v0.7.0 헌장 갱신 후만.
6. **다른 AI 도구 통합 금지(claude-output-charter 직계승).** Plane 통합이 `.cursor/rules`, `.codex/`, 루트 `AGENTS.md` 자동 쓰기로 확장되지 않는다.
7. **자동 push 책임 분산 금지.** 스킬·에이전트가 외부 트래커에 *직접 쓰지 않는다*. PostToolUse 훅 한 곳.
8. **마크다운 본문 오염 금지.** frontmatter 와 file-end 주석 블록 외에 본문(`#`/`##` 섹션, 표) 에 기계 메타 박지 않는다. 사람이 보는 첫 화면을 해치지 않는다.
9. **fail-closed 회귀 금지(secret-guard 와의 대비).** Plane sync 실패는 사용자 작업을 *블록하지 않는다*. 토큰 부재·네트워크 끊김·5xx 는 모두 stderr 경고 + skip. fail-closed 는 *secret-guard 한정*.
10. **헌장 폐기 시 *Superseded by* 표시.** 본 헌장이 v0.11.x 이상에서 변경된다면 v0.8.0 헌장과 동일하게 상태를 *Superseded by ...* 로 갱신 — 삭제하지 않는다 (이력 보존).
11. **사용자 직접 편집 우선.** integrations.json·plane.secret.json 은 사용자가 *직접* 작성. 플러그인이 자동 생성·자동 채움 X (`/integrations` 스킬은 *복사 가이드* 만).
12. **Plane API 변경 격리.** 모든 Plane HTTP 호출은 `hooks/lib/plane_sync.py::PlaneClient` 한 클래스에. `api_version` 필드는 사용자가 의도적으로 바꿀 수 있는 노브. v2 출시 후 자동 업그레이드 X.

## 분류표 (참조 매핑)

| 산출물 | 위치 | 이유 |
|--------|------|------|
| `integrations.json` | `.claude/integrations.json` (git 추적) | 훅이 자동 로드 → v0.9.0 헌장 D1 통과(사용 설정). 토큰 미포함. |
| `plane.secret.json` | `.claude/local/plane.secret.json` (gitignore 차단) | v0.9.0 헌장 D7: `.claude/local/` = 차단 영역. secret-guard `*.secret.json` 이 이중 보호. |
| `plane-sync.sh` / `plane-watch.sh` | `claude-code-plugin/project-lifecycle/hooks/` | 훅 스크립트. stack-watch/knowledge-watch 패턴 계승. |
| `lib/plane_sync.py` | `claude-code-plugin/project-lifecycle/hooks/lib/` | 단일 Python 모듈. config·HTTP·frontmatter·도메인 sync 의 두뇌. 두 wrapper(`plane-sync.sh`, `plane-watch.sh`) 가 `sys.path` 추가 후 import. |
| `/integrations` 스킬 | `claude-code-plugin/project-lifecycle/skills/integrations/` | 사용자가 *켜는* 절차 가이드. 자동 push 는 스킬 책임 X. |
| `<!-- plane-sync:* -->` 블록 | `docs/alm/lifecycle.md`, `docs/alm/tech-debt-registry.md` | B·C 도메인 매핑. 본문 끝에 단일 블록. |
| frontmatter (`plane_id` 등) | `docs/issues/*.md`, `.claude/local/plans/*/*/execution-plan.md` | A·D 도메인 매핑. `local` 모드에서는 생성 X. |

## 관련 문서

- `CHANGELOG.md` `[0.10.0]` 항목 — 출시 내역 및 활성화 가이드 (v0.9.0 → v0.10.0, 무액션 기본).
- `claude-code-plugin/project-lifecycle/hooks/plane-sync.sh` — PostToolUse 진입점.
- `claude-code-plugin/project-lifecycle/hooks/plane-watch.sh` — SessionStart 연결 보고.
- `claude-code-plugin/project-lifecycle/hooks/lib/plane_sync.py` — 단일 Python 모듈: config 파싱·도메인 매칭·frontmatter codec·file-end 주석 블록·Plane API HTTP 추상·도메인별 sync 함수의 두뇌. 두 wrapper(`plane-sync.sh`, `plane-watch.sh`) 가 `sys.path` 추가 후 import.
- `claude-code-plugin/project-lifecycle/hooks/integrations-template.json` — 사용자 시작 샘플.
- `claude-code-plugin/project-lifecycle/skills/integrations/SKILL.md` — 절차적 활성 가이드.
- `docs/direction/2026-04-29-claude-as-settings-only-charter.md` — `.claude/` = 사용 설정 전용.
- `docs/direction/2026-04-28-secret-file-guardrail-charter.md` — `*.secret.json` 기본 차단의 상위 정책.
- `docs/direction/2026-04-28-claude-output-charter.md` — 다른 AI 도구 통합 금지 상위 원칙.
- Plane API 명세 — `https://developers.plane.so/` (구현 시 §0 가정과 정합 보정).
