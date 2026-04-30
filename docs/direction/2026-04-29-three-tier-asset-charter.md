# 사내 자산 3계층(공유 · 운영 · 로컬) 분류 헌장

- **작성일**: 2026-04-29
- **반영 출시**: v0.8.0
- **관련 커밋**: (출시 시 추가)
- **상태**: Superseded by `2026-04-29-claude-as-settings-only-charter.md`(v0.9.0)
- **상위 헌장**: `2026-04-28-three-doc-set-charter.md`(v0.6.0), `2026-04-28-claude-output-charter.md`(v0.4.0)
- **참조 구현**: pkpk-api (`atms-backend/api`) — 커밋 `dafcaf6`(api-flows 도입), `83c630b`(3계층 재편)
- **대체 사유**: 본 헌장의 *three-tier* (공유/운영/로컬) 분류는 의미적으로 명확했으나, (1) symlink 패턴이 macOS/Linux 환경에 의존, (2) `.claude/` 와 `docs/` 양쪽에 자산이 분산되어 외부 도구·신규 합류자 입장에서 *어디를 봐야 하는지* 혼란, (3) 운영 자산(lifecycle/tech-debt/kpi/issues)도 결국 *문서 형태* 라 docs/ 로의 통합이 더 자연스러움. 후속 헌장(v0.9.0)에서 *.claude/ = 사용 설정만, docs/ = 모든 문서* 로 단순화. 본 헌장의 D1·D2·D5 (분류 자체)·D9·D10·D12 는 후속 헌장에서도 유효. D3 (symlink)·D4 (운영 자산 .claude/ 잔류) 는 폐기.

## 사용자 원문 요구사항

세션 중 사용자가 보낸 메시지를 시간순으로 보존한다(의역·축약 최소화).

### (1) 초기 문제 제기 — 자산 분류와 추적 정책

> .claude에서 팀 공유 자원으로 가져가야할 내용들이 어떤것이 있는가? 예를들어
> docs/에 이미 승격된 용어 및 문서와 같은 공유 및 개인(local)으로 안들고
> 있어도 될 자원을 구분하여 gitignore에서 빼던지 승격하여 git tracking
> 하도록 할지 고려해야한다.

### (2) 적용 방식 선택 — 하이브리드(옵션 C)

> C
>
> (옵션 C: 일부는 docs/ 로 물리 승격, 일부는 .gitignore negate 로 그 자리
> 추적, 로컬 전용은 차단 유지)

### (3) sync 리스크 차단 — symlink 패턴 + 플러그인 표준화 제안

> docs에 이미 있는 문서는 .claude의 파일은 심볼릭 링크로 관리하는것이
> 더 좋아보인다. docs와 .claude의 문서가 sync가 맞지않으면 문제가 발생할
> 수 있는 리스크를 가지고 있기때문이다. 플러그인의 00-setup때 이러한
> 내용도 반영하는것은 어떤가?

## 도출한 원칙 (5개)

1. **3계층으로 분류한다.** 모든 ALM 산출물은 *공유 자산* / *운영 자산* / *로컬 전용* 중 하나에 속한다. 분류 기준은 *기능적 책임* — 누가 읽고/쓰는가, 회귀 시 누구에게 영향이 가는가. 단순 "위치" 가 아니라 *왜 그 위치인지*가 본질.
2. **공유 자산은 `docs/` 단일 진실 + `.claude/<name>` 심볼릭 링크.** 사본을 둘 두지 않는다 — drift 위험 0. 플러그인이 `.claude/<name>` 경로를 가정하는 step·skill 은 symlink 로 자동 호환.
3. **운영 자산은 `.claude/` 직속 + `.gitignore` negate 로 추적.** 라이프사이클·기술 부채·KPI 같은 *플러그인이 작동하기 위해 읽고 쓰는* 자산은 `.claude/` 에 머무는 게 자연스럽다. negate 룰로 git 추적만 활성화하여 팀 가시성 확보.
4. **승격은 사용자 결정.** knowledge 헌장 D5 정합 — 플러그인은 *어떤 경우에도* 자동으로 `.claude/<name>` 을 `docs/<name>` 으로 이동시키지 않는다. 권유만. 명령 예시는 references 템플릿으로 제공.
5. **로컬 전용은 절대 자동 승격 금지.** `local/`, `settings.local.json` 같은 명시적 로컬 파일은 분류 재검토 대상이 아니다 — 일시적 작업 산출물·개인 설정의 본질이 그렇다.

## 설계 결정

| ID | 결정 | 근거 |
|----|------|------|
| D1 | 3계층 분류 — 공유(`docs/`) / 운영(`.claude/` negate) / 로컬(`.claude/` 차단) | 사용자 요구 (1) — gitignore에서 빼거나 승격할지 *구분*. 단일 차단(v0.7.x)·단일 추적 모두 사일런트 위험. |
| D2 | 공유 자산 위치 = `docs/<name>/` (실체) | knowledge 헌장 D5 패턴 확장. `docs/` 가 IDE 트리·GitHub UI·외부 협업 표준. |
| D3 | `.claude/<name>` 호환 심볼릭 링크 유지 | 사용자 요구 (3) — sync drift 차단. 플러그인 step·skill·에이전트가 가정하는 `.claude/<name>` 경로 호환성 보존. |
| D4 | 운영 자산 = `.claude/` 직속 + `.gitignore` negate 룰 | 사용자 요구 (1)·(2). `lifecycle.md`, `tech-debt-registry.md`, `kpi-definitions.md`, `issues/`, `secret-guard.json`, `settings.json`, `CLAUDE.md` 는 플러그인 작동 대상 — `.claude/` 잔류가 자연스러움. |
| D5 | 로컬 = `.claude/local/`, `.claude/settings.local.json` (차단 유지) | 실행계획서(governance) · stack 캐시 · 개인 IDE 설정. 일시성/개인성이 본질. |
| D6 | 신규 프로젝트는 *권유만*, 자동 승격 X | knowledge 헌장 D5 계승. 사용자가 `/00-setup` 신설 Step 에서 명시 결정 시에만. |
| D7 | 기존 프로젝트 마이그레이션은 *가이드만*, 자동 mv/ln 스크립트 ship X | 사용자 영역 침범 회피. CHANGELOG `Migration` 절에 명령 시퀀스 제공. |
| D8 | 권장 매핑은 *제시*하되 디렉토리명 자체는 사용자 결정 | `00-setup → team`, `03-architecture → architecture`, `08-maintenance → operations`, `policies → policies` 가 권장. 사용자가 `setup`/`maintenance` 등 다른 이름 선택 가능. |
| D9 | `.gitignore` 패턴 = `.claude/*` + 명시 negate (단일 라인 negate 무효화) | git 룰 — 부모 디렉토리가 ignore 되면 하위 negate 무효. 와일드카드 `.claude/*` 로 차단 후 명시적 negate 가 안전. |
| D10 | symlink 도 `.gitignore` negate 대상 | 다른 멤버 `clone` 시 즉시 호환 경로 동작. git 은 symlink 를 `mode 120000` 오브젝트로 추적. |
| D11 | Windows 호환성은 *경고만*, plugin 강제 X | symlink 미지원 환경(Windows w/o developer mode)에선 사용자 결정. 플러그인은 명령 예시만 제시. |
| D12 | 분류 기준 변경 시 본 헌장 갱신 후 SKILL.md 반영 | 새 카테고리(예: *보안 정책*, *감사 로그*) 도입 시 분류 재정의. |
| D13 | 다른 AI 도구 자동 동기화 금지 | claude-output-charter 원칙 5 계승. `docs/` 승격은 *git 가시성* 확보 한정 — `.cursor/`, `.codex/`, `AGENTS.md` 자동 쓰기 금지. |

## 분류표 (참조 매핑)

| 산출물 | 계층 | 권장 위치 | 이유 |
|--------|------|-----------|------|
| `glossary.md`, `product-requirements.md`, `technical-requirements.md`, `index.md` (knowledge) | 공유 | `docs/knowledge/` (이미 v0.6.0 에서 확정) | 사내 3종 문서 헌장 D5 |
| `tech-stack.md`, `system-design.md`, `data-model.md`, `api-spec.md` (03-architecture) | 공유 | `docs/architecture/` | ADR·시스템 설계는 변경 영향 분석 기준선·온보딩 핵심 |
| `monitoring-report.md`, `feedback-analysis.md`, `retrospective.md`, `incident-reports/` (08-maintenance) | 공유 | `docs/operations/` | 운영 학습 자산. blameless 회고는 팀 가시성 본질 |
| `project-config.md`, `team-conventions.md` (00-setup) | 공유 | `docs/team/` | 팀 컨벤션은 모든 멤버에 동일 적용 |
| `decisions.md` (policies) | 공유 | `docs/policies/` | Lightweight ADR — 결정의 단일 진입점 |
| `lifecycle.md`, `tech-debt-registry.md`, `kpi-definitions.md` | 운영 | `.claude/` (negate) | 플러그인이 갱신하는 ALM 추적 자산 |
| `issues/` | 운영 | `.claude/issues/` (negate) | 외부 트래커 부재 시 대체 (CLAUDE.md 에 명시) |
| `secret-guard.json` | 운영 | `.claude/` (negate) | 보안 정책 — 멤버 간 drift 방지 필수 |
| `settings.json` | 운영 | `.claude/` (negate) | 프로젝트 공통 Claude Code 설정 |
| `CLAUDE.md` | 운영 | `.claude/` (negate) | AI 컨텍스트 — 멤버·도구 간 일관성 보장 |
| `local/plans/<branch>/...` | 로컬 | `.claude/local/` (차단) | 브랜치별 일시 실행계획서 |
| `local/stack.json` | 로컬 | `.claude/local/` (차단) | 03-architecture 해시 검증 캐시 |
| `settings.local.json` | 로컬 | `.claude/` (명시 차단) | 개인 IDE/단축키 설정 |

## 미래 변경 시 지킬 것

이 헌장은 후속 변경에 대한 **불변 가드레일**이다. 위반 시 본 문서를 먼저 갱신하거나(=원칙 변경의 근거 기록) 설계를 바꾼다.

1. **자동 승격 금지.** `.claude/<name>` 을 `docs/<name>` 으로 자동 이동시키는 코드를 만들지 않는다. SKILL.md 의 신설 Step 은 *권유와 명령 시퀀스 제시*만 한다.
2. **사본 두지 않기.** 공유 자산을 `docs/` 와 `.claude/` 양쪽에 *복사*하지 않는다. 단일 진실 + symlink. 사본 동기화 메커니즘(rsync, hook 등) 도입 시 본 헌장 갱신 필수.
3. **로컬 자산 자동 승격 금지.** `local/`, `settings.local.json` 의 분류는 변경 대상이 아니다. 사용자가 의도해서 옮길 수는 있으나 플러그인이 *제안*하지 않는다.
4. **분류 기준 변경은 헌장 갱신 우선.** 새 산출물 카테고리 추가 시 분류표 재정의 → 본 헌장 갱신 → SKILL.md 반영 순서. 역순 금지.
5. **`docs/` 하위 명명 자동 결정 금지.** 권장 매핑(`team`, `architecture`, `operations`, `policies`) 은 *제시*만. 사용자가 `setup`/`maintenance` 같은 다른 이름 선택 가능. 플러그인은 강제하지 않는다.
6. **다른 AI 도구 통합 금지.** 본 헌장의 `docs/` 승격이 `.cursor/rules`, `.codex/`, 루트 `AGENTS.md` 자동 생성으로 확장되지 않는다(claude-output-charter 원칙 5 직접 계승, three-doc-set 헌장 미래 변경 #7 정합).
7. **Windows 등 symlink 미지원 환경 강제 금지.** `mklink` 또는 `git config core.symlinks=true` 강요 X. 명령 예시는 POSIX symlink 기준으로 제공하되, Windows 사용자에겐 *주의*만 명시.
8. **운영 자산 ↔ 공유 자산 재분류는 신중하게.** 예컨대 `tech-debt-registry.md` 를 `docs/` 로 옮기자는 제안은 *팀 가시성 vs 플러그인 갱신 충돌* 트레이드오프. 옮기려면 본 헌장 갱신 먼저.

## 관련 문서

- `CHANGELOG.md` `[0.8.0]` 항목 — 출시 내역 및 마이그레이션 가이드
- `claude-code-plugin/project-lifecycle/skills/00-setup/SKILL.md` — 본 헌장의 절차적 구현 (Step 8 신설)
- `claude-code-plugin/project-lifecycle/skills/00-setup/references/three-tier-classification-template.md` — 분류표·명령 시퀀스 시작 샘플
- `docs/direction/2026-04-28-three-doc-set-charter.md` — 본 헌장의 원형 (knowledge → docs/ 승격 패턴)
- `docs/direction/2026-04-28-claude-output-charter.md` — 상위 출력 단일성·도구 비종속 원칙
- pkpk-api 적용 결과 (참조 구현):
  - 커밋 `dafcaf6` — 사내 지식에 API 흐름(api-flows) 축 도입
  - 커밋 `83c630b` — 3계층 자산 재편 (4 디렉토리 승격 + 7 운영 자산 negate + 5 로컬 차단)
