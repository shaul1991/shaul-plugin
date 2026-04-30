# shaul-plugin

> **project-lifecycle** — Claude Code로 프로젝트 전 수명주기를 단계별로 가이드하는 플러그인.

즉흥 코딩의 비용을 줄이고, 모든 작업을 **계획 → 검증 → 실행 → 재검증**의 거버넌스로 통과시킵니다. 모든 산출물은 `.claude/` 하위에 단계별로 정리되며 `.claude/`는 기본적으로 git 추적에서 제외됩니다. 공유가 필요한 산출물은 사용자가 `.claude/` 밖(예: `docs/`)으로 직접 옮길 때만 추적되는 **사용자 결정 추적** 구조입니다.

---

## 핵심 기능

- **9-Phase 라이프사이클 스킬** — 초기 설정(00-setup)부터 운영/회고(08-maintenance)까지 단계별 베스트 프랙티스와 템플릿을 제공.
- **Plan-Review-Execute-Reverify 거버넌스** — 모든 Phase 진입 시 실행계획서 작성 → 사용자 명시적 수락 → 실행 → 재검증의 4단계를 강제.
- **브랜치별 실행계획 작업 영역** — `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md`에 자동 저장. 브랜치를 갈아타도 계획이 섞이지 않고, 세션이 종료되어도 디스크에 기록으로 남습니다.
- **SessionStart 자동 부트스트랩** — 사용자 프로젝트에서 세션이 시작되면 `.claude/local/plans/` 디렉토리와 `.gitignore` 처리가 자동으로 보장됩니다 (idempotent, git 저장소에서만 동작).
- **사내 3종 문서 통합 관리 (v0.6.0)** — 신규 `knowledge` 스킬이 용어집·기획요구·기술요구를 인덱스(lazy-load) 한 묶음으로 관리합니다. 다른 AI 도구(Cursor·Codex·Copilot·Gemini 등) 도달이 필요하면 사용자가 인덱스를 루트 `AGENTS.md` 로 *수동 승격*(이동·심링크). 신규 `domain-liaison` 에이전트가 팀별·도메인 간 vocabulary 일관성을 책임집니다.
- **시크릿 파일 가드 (v0.7.0)** — `Read`/`Edit`/`Write`/`Bash` 가 `.env`, `.env.*` 같은 시크릿 파일을 만지려 시도하면 *무조건* 차단(또는 사용자 확인 프롬프트). 어느 step·skill·에이전트에서도 동일 적용. 사용자가 `.claude/secret-guard.json` 한 파일만 편집해 정책을 추가·삭제 가능. 일시 해제는 `CLAUDE_PLUGIN_SECRET_GUARD` 환경변수에 `off`/`0`/`false`/`no` 중 하나(대소문자 무관) 설정. python3 부재·정책 평가 불가 시에는 *fail-closed*(기본 차단)로 동작.
- **자산 위치 정리 (v0.9.0)** — `00-setup` Step 8 에서 *.claude/ = Claude/플러그인 사용 설정 전용*(`CLAUDE.md`·`secret-guard.json`·`settings.json`), *모든 문서는 `docs/`* 의 의미별 하위 폴더로(architecture·operations·team·policies·alm·issues·knowledge), 로컬은 `.claude/local/` 차단 권유. v0.8.0 의 symlink 패턴은 폐기되어 macOS/Linux/Windows 환경 비종속. 자동 이동은 *하지 않으며* 사용자 명시 결정 후 명령 시퀀스 제시. v0.7.x 이전·v0.8.x 모두 하위 호환 보장.
- **외부 트래커 옵션 통합 (v0.10.0)** — `.claude/integrations.json` 한 파일로 [Plane Opensource](https://plane.so/) 연동을 켜고 끔. 모드 3종: `local`(default, v0.9.0 비트단위 동일) / `plane` / `both`. 활성 시 PostToolUse 훅이 4개 도메인(`docs/issues/`·`docs/alm/lifecycle.md`·`docs/alm/tech-debt-registry.md`·`.claude/local/plans/<branch>/<NN-phase>/execution-plan.md`)을 자동 push. 토큰은 `.claude/local/plane.secret.json` (gitignore 차단 + secret-guard `*.secret.json` 자동 차단 이중 보호) 또는 `CLAUDE_PLUGIN_PLANE_TOKEN`/`PLANE_API_TOKEN` 환경변수. *Fail-open* — 네트워크 실패·5xx 는 stderr 경고만, 사용자 작업은 블록되지 않음. 활성 절차는 `/integrations` 스킬 안내. 자세한 내용은 헌장 `docs/direction/2026-04-30-plane-integration-charter.md`.
- **16개 스킬 + 15개 전문가 에이전트** — Phase별 스킬 외에 `dashboard`, `governance`, `sync-check`, `impact-analysis`, `debt-collector`, `gate-keeper`, `knowledge` 같은 크로스커팅 유틸리티와 시니어 페르소나를 가진 에이전트가 함께 동작합니다.
- **ALM 추적성** — `.claude/lifecycle.md`, `.claude/tech-debt-registry.md`, `.claude/kpi-definitions.md`로 요구사항·설계·코드·테스트·KPI의 연결을 관리. (공유가 필요하면 사용자가 직접 추적 영역으로 이동)

---

## 요구사항

- Claude Code (플러그인을 로드할 수 있는 환경)
- `git` (브랜치 인식 및 SessionStart 부트스트랩 가드용)
- `bash` (SessionStart 훅 스크립트용)

---

## 설치

### 방법 1. 마켓플레이스에서 설치 (권장)

이 저장소 자체가 Claude Code 플러그인 마켓플레이스로 동작합니다
(`.claude-plugin/marketplace.json` 보유). Claude Code 세션에서 다음을 실행합니다:

```text
/plugin marketplace add shaul1991/shaul-plugin
/plugin install project-lifecycle@shaul-plugin
```

업데이트가 필요할 때는:

```text
/plugin marketplace update shaul-plugin
```

### 방법 2. 로컬 마켓플레이스로 설치 (개발/테스트용)

저장소를 클론한 디렉토리를 마켓플레이스로 등록하면 소스 변경이 즉시 반영됩니다:

```text
/plugin marketplace add /path/to/shaul-plugin
/plugin install project-lifecycle@shaul-plugin
```

설치 직후 새 세션을 한 번 시작하면, 현재 작업 중인 git 저장소에 다음이 자동으로 만들어집니다:

```
<your-project>/
├── .gitignore             ← `.claude/`가 한 줄 추가됨 (기존 내용 보존)
└── .claude/
    └── local/plans/       ← 브랜치별 실행계획 작업 영역
```

`.claude/` 폴더 전체가 ignore되므로 플러그인 산출물은 기본적으로 git에 포함되지 않습니다. 레거시 `.claude/local/` 라인이 있던 v0.3.x 프로젝트는 SessionStart 훅이 자동으로 `.claude/`로 교체합니다. git 저장소가 아닌 디렉토리에서는 어떤 변경도 하지 않습니다.

---

## 60초 빠른 시작

1. 프로젝트 디렉토리에서 Claude Code 세션을 엽니다 (위 부트스트랩이 자동 실행).
2. `"프로젝트 설정"` 또는 `"초기 설정"`이라고 입력해 Phase 0을 시작합니다.
3. 플러그인이 실행계획서를 작성해 `.claude/local/plans/<branch>/00-setup/execution-plan.md`에 저장합니다.
4. 사용자에게 검토를 요청합니다. **승인**하면 실행이 시작되고, 산출물이 `.claude/00-setup/`에 생성됩니다.
5. 실행 후 재검증 결과를 보고하고 `.claude/lifecycle.md`에 이력이 기록됩니다.
6. 팀과 공유할 산출물(예: PRD)이 생기면 `git mv .claude/02-planning/prd.md docs/02-planning/prd.md`처럼 `.claude/` 밖으로 직접 이동시킵니다 — 추적 여부는 전적으로 사용자 결정입니다.

이후 단계는 `"PRD 작성해줘"`(Phase 2), `"기술 스택 선정"`(Phase 3) 같은 키워드로 필요할 때마다 호출하면 됩니다. 전체 플로우를 순서대로 진행할 필요 없이 **부분 사용**이 가능합니다.

---

## 저장소 구조

```
shaul-plugin/
├── README.md                                 ← 이 파일 (랜딩 페이지)
├── CHANGELOG.md                              ← 버전별 변경 이력
├── .claude-plugin/
│   └── marketplace.json                      ← 마켓플레이스 매니페스트 (이 저장소를 마켓으로 노출)
└── claude-code-plugin/
    └── project-lifecycle/
        ├── README.md                         ← 상세 매뉴얼 (스킬·에이전트 카탈로그)
        ├── .claude-plugin/plugin.json
        ├── hooks/                            ← SessionStart/PreToolUse/PostToolUse 훅 + lib/
        ├── agents/                           ← 15개 전문가 에이전트 정의
        └── skills/                           ← 17개 스킬 정의 (Phase + 크로스커팅 + integrations)
```

---

## 더 알아보기

스킬과 에이전트의 전체 카탈로그, Plan-Review-Execute-Reverify의 상세 절차, ALM 통합 설명은 다음 문서에서 다룹니다:

- 📖 [`claude-code-plugin/project-lifecycle/README.md`](claude-code-plugin/project-lifecycle/README.md) — 플러그인 상세 매뉴얼
- ⚙️ [`claude-code-plugin/project-lifecycle/skills/governance/SKILL.md`](claude-code-plugin/project-lifecycle/skills/governance/SKILL.md) — 거버넌스 4단계 프로세스 정의
- 📂 [`claude-code-plugin/project-lifecycle/skills/governance/references/execution-plan-template.md`](claude-code-plugin/project-lifecycle/skills/governance/references/execution-plan-template.md) — 실행계획서 템플릿
- 🧭 [`docs/direction/`](docs/direction/) — 플러그인 개발 방향성·요구사항·아키텍처 결정 영구 기록 (시간순, ADR 형식)

---

## 기여

- 브랜치 네이밍은 `claude/<주제>` 또는 `feature/<주제>` 컨벤션을 따릅니다.
- 작업 중 작성되는 실행계획은 자동으로 `.claude/local/plans/<branch>/...`에 저장되며 `.claude/` 폴더 전체 ignore의 일부로 git 추적에서 제외됩니다. 합의가 끝난 계획·산출물 중 팀과 공유가 필요한 것만 사용자가 직접 `.claude/` 밖(예: `docs/`)으로 이동시켜 추적 영역에 둡니다.
- 사용자(저장소 오너)로부터 **플러그인 개발 방향성·요구사항·아키텍처 결정**을 새로 받았다면, 그 내용은 `docs/direction/`에 영구 기록을 남깁니다 (컨벤션은 [`docs/direction/README.md`](docs/direction/README.md) 참조). 구현 결과는 출시·CHANGELOG로, *왜 그렇게 만들었는가*는 이 디렉토리로 분리해 기록합니다.
- `claude-code-plugin/project-lifecycle/` 하위(스킬·에이전트·훅·`plugin.json`)를 수정하면 마켓플레이스 매니페스트(`.claude-plugin/marketplace.json`)의 `version` 및 해당 plugin entry의 `version`을 함께 갱신합니다.
- 사용자에게 영향을 주는 변경은 `CHANGELOG.md`에 항목을 추가합니다(Keep a Changelog 형식, SemVer).
- PR을 올리기 전 `governance` 스킬의 재검증 체크리스트를 먼저 통과시키는 것을 권장합니다.
