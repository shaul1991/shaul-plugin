# shaul-plugin

> **project-lifecycle** — Claude Code로 프로젝트 전 수명주기를 단계별로 가이드하는 플러그인.

즉흥 코딩의 비용을 줄이고, 모든 작업을 **계획 → 검증 → 실행 → 재검증**의 거버넌스로 통과시킵니다. 산출물은 `docs/`에 단계별로 정리되고, 작업용 실행계획은 브랜치별로 자동 분리되어 git 추적에서 안전하게 제외됩니다.

---

## 핵심 기능

- **9-Phase 라이프사이클 스킬** — 초기 설정(00-setup)부터 운영/회고(08-maintenance)까지 단계별 베스트 프랙티스와 템플릿을 제공.
- **Plan-Review-Execute-Reverify 거버넌스** — 모든 Phase 진입 시 실행계획서 작성 → 사용자 명시적 수락 → 실행 → 재검증의 4단계를 강제.
- **브랜치별 실행계획 작업 영역** — `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md`에 자동 저장. 브랜치를 갈아타도 계획이 섞이지 않고, 세션이 종료되어도 디스크에 기록으로 남습니다.
- **SessionStart 자동 부트스트랩** — 사용자 프로젝트에서 세션이 시작되면 `.claude/local/plans/` 디렉토리와 `.gitignore` 처리가 자동으로 보장됩니다 (idempotent, git 저장소에서만 동작).
- **15개 스킬 + 14개 전문가 에이전트** — Phase별 스킬 외에 `dashboard`, `governance`, `sync-check`, `impact-analysis`, `debt-collector`, `gate-keeper` 같은 크로스커팅 유틸리티와 시니어 페르소나를 가진 에이전트가 함께 동작합니다.
- **ALM 추적성** — `docs/lifecycle.md`, `docs/tech-debt-registry.md`, `docs/kpi-definitions.md`로 요구사항·설계·코드·테스트·KPI의 연결을 관리.

---

## 요구사항

- Claude Code (플러그인을 로드할 수 있는 환경)
- `git` (브랜치 인식 및 SessionStart 부트스트랩 가드용)
- `bash` (SessionStart 훅 스크립트용)

---

## 설치

저장소를 클론한 뒤 **저장소 루트**에서 다음 명령을 실행합니다:

```bash
claude plugin add ./claude-code-plugin/project-lifecycle.plugin
```

다른 위치에서 설치하려면 `.plugin` 파일의 절대경로를 사용하세요. 예:

```bash
claude plugin add /path/to/shaul-plugin/claude-code-plugin/project-lifecycle.plugin
```

설치 직후 새 세션을 한 번 시작하면, 현재 작업 중인 git 저장소에 다음이 자동으로 만들어집니다:

```
<your-project>/
├── .gitignore             ← `.claude/local/`이 한 줄 추가됨 (기존 내용 보존)
└── .claude/local/plans/   ← 브랜치별 실행계획 작업 영역
```

git 저장소가 아닌 디렉토리에서는 어떤 변경도 하지 않습니다.

---

## 60초 빠른 시작

1. 프로젝트 디렉토리에서 Claude Code 세션을 엽니다 (위 부트스트랩이 자동 실행).
2. `"프로젝트 설정"` 또는 `"초기 설정"`이라고 입력해 Phase 0을 시작합니다.
3. 플러그인이 실행계획서를 작성해 `.claude/local/plans/<branch>/00-setup/execution-plan.md`에 저장합니다.
4. 사용자에게 검토를 요청합니다. **승인**하면 실행이 시작되고, 산출물이 `docs/00-setup/`에 생성됩니다.
5. 실행 후 재검증 결과를 보고하고 `docs/lifecycle.md`에 이력이 기록됩니다.

이후 단계는 `"PRD 작성해줘"`(Phase 2), `"기술 스택 선정"`(Phase 3) 같은 키워드로 필요할 때마다 호출하면 됩니다. 전체 플로우를 순서대로 진행할 필요 없이 **부분 사용**이 가능합니다.

---

## 저장소 구조

```
shaul-plugin/
├── README.md                                 ← 이 파일 (랜딩 페이지)
└── claude-code-plugin/
    ├── project-lifecycle.plugin              ← 마켓플레이스 메타데이터
    └── project-lifecycle/
        ├── README.md                         ← 상세 매뉴얼 (스킬·에이전트 카탈로그)
        ├── .claude-plugin/plugin.json
        ├── hooks/                            ← SessionStart 부트스트랩 스크립트
        ├── agents/                           ← 14개 전문가 에이전트 정의
        └── skills/                           ← 15개 스킬 정의 (Phase + 크로스커팅)
```

---

## 더 알아보기

스킬과 에이전트의 전체 카탈로그, Plan-Review-Execute-Reverify의 상세 절차, ALM 통합 설명은 다음 문서에서 다룹니다:

- 📖 [`claude-code-plugin/project-lifecycle/README.md`](claude-code-plugin/project-lifecycle/README.md) — 플러그인 상세 매뉴얼
- ⚙️ [`claude-code-plugin/project-lifecycle/skills/governance/SKILL.md`](claude-code-plugin/project-lifecycle/skills/governance/SKILL.md) — 거버넌스 4단계 프로세스 정의
- 📂 [`claude-code-plugin/project-lifecycle/skills/governance/references/execution-plan-template.md`](claude-code-plugin/project-lifecycle/skills/governance/references/execution-plan-template.md) — 실행계획서 템플릿

---

## 기여

- 브랜치 네이밍은 `claude/<주제>` 또는 `feature/<주제>` 컨벤션을 따릅니다.
- 작업 중 작성되는 실행계획은 자동으로 `.claude/local/plans/<branch>/...`에 저장되며 git 추적에서 제외됩니다. 합의가 끝난 계획만 사용자가 직접 `docs/`로 승격(promote)합니다.
- PR을 올리기 전 `governance` 스킬의 재검증 체크리스트를 먼저 통과시키는 것을 권장합니다.
