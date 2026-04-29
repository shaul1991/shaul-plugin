# `.claude/` = 사용 설정 전용, 모든 문서는 `docs/` 로 헌장

- **작성일**: 2026-04-29
- **반영 출시**: v0.9.0
- **관련 커밋**: (출시 시 추가)
- **상태**: Active
- **상위 헌장**: `2026-04-28-three-doc-set-charter.md`(v0.6.0), `2026-04-28-claude-output-charter.md`(v0.4.0)
- **대체 헌장**: `2026-04-29-three-tier-asset-charter.md`(v0.8.0) 의 D3·D4 폐기
- **참조 구현**: pkpk-api (`atms-backend/api`) — 커밋 `b6e07a2`(정책 재정의)

## 사용자 원문 요구사항

세션 중 사용자가 보낸 메시지를 시간순으로 보존한다(의역·축약 최소화).

### (1) v0.8.0 적용 후 잔존 의문 — symlink 5개 추적 필요성

> .gitignore에서
>
> !.claude/00-setup
> !.claude/03-architecture
> !.claude/08-maintenance
> !.claude/policies
> !.claude/knowledge
> !.claude/issues/
>
> 이러한 폴더는 없어도 되지 않나? 이미 docs/에 존재하니까 불필요하지 않나 싶은데

### (2) 정책 재정의 — `.claude/` = 설정만, 문서는 `docs/`

> .claude 폴더에서는 .claude 사용 설정 등에 대한 내용만 유지하고, 문서는 docs로 승격하여 관리한다.
> 팀 내부에서는 macos로 통일되어있는상태이다.

## 도출한 원칙 (5개)

1. **`.claude/` 는 *사용 설정 전용*.** Claude Code·플러그인이 *작동을 위해 직접 읽고 쓰는* 설정만 둔다 — `CLAUDE.md`(AI 컨텍스트), `secret-guard.json`(보안 정책), `settings.json`(Claude Code 공통 설정). 문서·이력·이슈 같은 *읽고 쓰는 정보 자산* 은 `.claude/` 에 두지 않는다.
2. **모든 문서는 `docs/` 로 통일.** ALM 추적 자산(lifecycle, tech-debt, kpi)·이슈·아키텍처·운영·정책·팀 컨벤션·지식 모두 `docs/` 의 의미별 하위 폴더에 둔다. 단일 진입점 — 신규 합류자도 외부 협업자도 `docs/` 만 보면 충분.
3. **symlink 패턴 폐기.** v0.8.0 의 `.claude/<원래>` → `docs/<새>` 호환 symlink 는 도입하지 않는다. 플러그인 내부 cross-ref 도 `docs/<name>` 으로 직접 작성. macOS/Linux/Windows 환경 비종속.
4. **로컬 격리는 유지.** `.claude/local/`, `.claude/settings.local.json` 은 *로컬 전용* 으로 차단 유지 (v0.8.0 D5 계승). 일시 작업·개인 설정은 docs/ 로 가지 않는다.
5. **사용자 결정 우선 + 자동 승격 금지** (knowledge 헌장 D5 / v0.8.0 D6·D7 계승). 본 플러그인은 어떤 경우에도 `.claude/<x>` 를 `docs/<x>` 로 *자동 이동시키지 않는다*. 사용자 명시 결정 후 명령 시퀀스를 따른다.

## 설계 결정

| ID | 결정 | 근거 |
|----|------|------|
| D1 | `.claude/` 잔류 자산 = `CLAUDE.md`, `secret-guard.json`, `settings.json` (+ `local/`, `settings.local.json` 로컬) | 사용자 요구 (2). 셋 다 *Claude Code/플러그인이 자동 로드·평가* 하는 설정. 문서 형태가 아님. |
| D2 | 모든 *문서* → `docs/<카테고리>/` | 사용자 요구 (2). 단일 진입점 + IDE/GitHub UI 가시성. |
| D3 | symlink 패턴 *도입 안 함* | 사용자 요구 (1)·(2). v0.8.0 D3 폐기. macOS 통일 환경 한정 도입 의미가 약함 — 다른 OS 호환·관리 비용 감소 효과가 우선. |
| D4 | 운영 자산(`lifecycle.md`, `tech-debt-registry.md`, `kpi-definitions.md`) → `docs/alm/` | "ALM 추적 자산" 의미 응집. `docs/operations/` (Phase 8 산출물) 와 분리 — 후자는 *Phase 산출물*, 전자는 *플러그인 ALM 추적*. |
| D5 | 이슈 트래킹 → `docs/issues/` | 외부 트래커 부재 시 대체. ALM 추적과는 별개 의미(트래커 대체)이므로 별도 폴더. |
| D6 | `docs/` 권장 카테고리: `knowledge`, `architecture`, `operations`, `team`, `policies`, `alm`, `issues` | knowledge 는 v0.6.0 표준. 나머지는 v0.8.0 D2 계승 + alm/issues 추가. 사용자가 다른 이름 선택 가능 (헌장 D8 v0.8.0 계승). |
| D7 | `.gitignore` 패턴 = `.claude/*` + 명시 negate 3개 + `.claude/settings.local.json` 명시 차단 | v0.8.0 D9 계승. 단순화: negate 가 7개에서 3개로 축소. |
| D8 | 운영 자산 갱신은 docs/ 안에서 수행 (CLAUDE.md, secret-guard.json, settings.json 만 .claude/) | 플러그인 step·skill·에이전트가 *항상 docs/<name>* 경로로 참조. v0.8.0 D3 (symlink 호환성) 가 폐기되었으므로 직접 참조 필수. |
| D9 | 신규 프로젝트는 *권유만*, 자동 마이그레이션 X | knowledge 헌장 D5 / v0.8.0 D6·D7 계승. |
| D10 | 기존 v0.8.0 적용 프로젝트는 *옵션 마이그레이션* | symlink 폐기 + `docs/alm/`·`docs/issues/` 신설. 가이드는 CHANGELOG `[0.9.0]` 에 명시. |
| D11 | v0.8.0 헌장의 D1·D2·D5·D9·D10·D12 는 본 헌장에서도 *유효*. D3·D4 만 폐기 | 분류 기준(기능적 책임), `.gitignore` 와일드카드 + negate 패턴, 외부 AI 도구 통합 금지 등은 그대로. |

## 분류표 (참조 매핑)

| 산출물 | 위치 | 이유 |
|--------|------|------|
| `CLAUDE.md` | `.claude/CLAUDE.md` | Claude Code 자동 로드. AI 컨텍스트 = 사용 설정. |
| `secret-guard.json` | `.claude/secret-guard.json` | PreToolUse 훅 자동 로드. 사용 설정. |
| `settings.json` | `.claude/settings.json` | Claude Code 자동 로드. 사용 설정. |
| `glossary.md`, `product-requirements.md`, `technical-requirements.md`, `index.md`, `api-flows/` | `docs/knowledge/` | three-doc-set 헌장 D5 (이미 docs/) |
| `tech-stack.md`, `system-design.md`, `data-model.md`, `api-spec.md` | `docs/architecture/` | Phase 3 산출물 |
| `monitoring-report.md`, `feedback-analysis.md`, `retrospective.md`, `incident-reports/` | `docs/operations/` | Phase 8 산출물 |
| `project-config.md`, `team-conventions.md` | `docs/team/` | 팀 컨벤션 |
| `decisions.md` (Lightweight ADR) | `docs/policies/` | 결정의 단일 진입점 |
| `lifecycle.md`, `tech-debt-registry.md`, `kpi-definitions.md` | `docs/alm/` | ALM 추적 자산 (NEW) |
| `issues/` (외부 트래커 대체) | `docs/issues/` | 트래커 대체 (NEW) |
| 실행계획서 | `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md` (차단) | 일시 작업. v0.8.0 D5 계승 |
| 스택 캐시 | `.claude/local/stack.json` (차단) | 03-architecture 해시 검증 |
| 개인 설정 | `.claude/settings.local.json` (차단) | 개인 IDE/단축키 |

## 미래 변경 시 지킬 것

이 헌장은 후속 변경에 대한 **불변 가드레일**이다. 위반 시 본 문서를 먼저 갱신하거나(=원칙 변경의 근거 기록) 설계를 바꾼다.

1. **`.claude/` 잔류 기준 = "Claude/플러그인이 자동 로드·평가하는 설정만".** 문서 형태(`*.md`)는 모두 `docs/` 로 간다. 향후 Claude Code 가 자동 로드하는 *새 설정 파일* (예: `permissions.json`) 도입 시 `.claude/` 잔류 가능 — 본 헌장의 *기준* 으로 판단.
2. **symlink 도입 금지.** v0.8.0 의 `.claude/<원래>` → `docs/<새>` 호환 symlink 는 *어떤 환경에서도* 도입하지 않는다. 플러그인 step·skill·에이전트가 `.claude/<x>` 경로를 가정하면 코드를 *수정*하여 `docs/<x>` 로 직접 참조한다.
3. **자동 마이그레이션 스크립트 ship X** (knowledge 헌장 D5 / v0.8.0 D7 계승). 사용자 영역 침범 회피 — 명령 시퀀스 *제시* 만.
4. **`docs/` 카테고리 자동 결정 X** (v0.8.0 D8 계승). 권장만. `alm`/`issues` 같은 새 카테고리도 사용자가 다른 이름 선택 가능.
5. **다른 AI 도구 통합 금지** (claude-output-charter 원칙 5 / 모든 선행 헌장 계승). `docs/` 승격이 `.cursor/rules`·`.codex/`·루트 `AGENTS.md` 자동 생성으로 확장되지 않는다.
6. **운영 자산 ↔ 사용 설정 재분류는 신중하게.** 예컨대 `secret-guard.json` 을 `docs/` 로 옮기자는 제안은 *가드 자동 로드 위치 변경* 을 뜻한다 — 훅 코드 동시 수정 필요. 본 헌장 갱신 우선.
7. **헌장 폐기 시 *Superseded by* 표시.** 본 헌장이 v0.10.x 이상에서 또 변경된다면 v0.8.0 헌장과 동일하게 상태를 *Superseded by ...* 로 갱신 — 삭제하지 않는다 (이력 보존).
8. **단일 진입점 원칙.** `docs/` 안의 *어떤 파일* 도 `.claude/` 에 *복사* 두지 않는다. 사본 동기화 메커니즘 도입 시 본 헌장 갱신 필수 — 사실상 D2 의 단순함이 깨지는 변경.

## 관련 문서

- `CHANGELOG.md` `[0.9.0]` 항목 — 출시 내역 및 마이그레이션 가이드 (v0.8.0 → v0.9.0)
- `claude-code-plugin/project-lifecycle/skills/00-setup/SKILL.md` — 본 헌장의 절차적 구현 (Step 8 재작성)
- `claude-code-plugin/project-lifecycle/skills/00-setup/references/three-tier-classification-template.md` — 본 헌장에 맞춰 단순화
- `docs/direction/2026-04-29-three-tier-asset-charter.md` — 본 헌장이 대체. 상태 *Superseded*. 분류 사유·미래 변경 가드레일 다수는 여전히 유효.
- `docs/direction/2026-04-28-three-doc-set-charter.md` — 본 헌장의 원형 (knowledge → docs/ 승격 패턴, D5 계승)
- `docs/direction/2026-04-28-claude-output-charter.md` — 상위 출력 단일성·도구 비종속 원칙
- pkpk-api 적용 결과:
  - 커밋 `b6e07a2` — 정책 재정의 (운영 자산 4종 docs/ 이동 + symlink 5개 폐기 + cross-ref 일괄 갱신)
