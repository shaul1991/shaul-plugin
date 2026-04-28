# Project Lifecycle Plugin

프로젝트 전체 라이프사이클을 단계별로 가이드하는 Claude Code 플러그인.

초기 설정부터 아이디어 수집, 기획, 설계, 디자인, 구현, 인프라, QA, 운영/회고까지 — 각 단계의 베스트 프랙티스와 템플릿을 제공하며, ALM(Application Lifecycle Management) 관점에서 추적성과 거버넌스를 관리합니다.

## 플로우 개요

```
Phase 0: 초기 설정 → Phase 1: 아이디어 수집 → Phase 2: 기획
    → Phase 3: 아키텍처/설계 → Phase 4: 디자인/프로토타입
    → Phase 5: 구현 → Phase 6: 인프라/DevOps → Phase 7: QA/테스트
    → Phase 8: 운영/회고 (지속 반복)
```

## 스킬 목록

| 스킬 | 트리거 키워드 | 설명 |
|------|-------------|------|
| `dashboard` | "프로젝트 현황", "대시보드", "다음 단계" | 전체 진행 상태 조회 및 다음 단계 안내 |
| `governance` | "실행 계획", "거버넌스", "계획 수립" | Plan-Review-Execute-Reverify 프로세스 |
| `00-setup` | "프로젝트 설정", "초기 설정", "컨벤션 정의" | 프로젝트 환경 설정, 팀 컨벤션, CLAUDE.md 생성 |
| `01-ideation` | "아이디어", "브레인스토밍", "문제 정의" | 아이디어 수집, 평가, 브리프 작성 |
| `02-planning` | "기획", "PRD", "요구사항", "유저 스토리" | PRD, 유저 스토리, 스코프 정의, KPI 설정 |
| `03-architecture` | "아키텍처", "시스템 설계", "기술 스택", "DB 설계" | 기술 스택 선정, 시스템/DB/API 설계, 기술 부채 기록 |
| `04-design` | "디자인", "와이어프레임", "프로토타입", "UI" | 정보 구조, 와이어프레임, 디자인 시스템, 인터랙션 명세 |
| `05-implementation` | "구현", "코딩", "개발 시작", "코드 컨벤션" | 프로젝트 초기화, 코드 컨벤션, 기능 구현, 셀프 리뷰 |
| `06-infra` | "인프라", "CI/CD", "Docker", "배포", "Terraform" | 컨테이너화, CI/CD, IaC, 모니터링, 보안 |
| `07-qa` | "QA", "테스트", "릴리즈 점검" | 테스트 전략, 인수 테스트, 릴리즈 체크리스트 |
| `08-maintenance` | "운영", "회고", "포스트모템", "유지보수" | 에러 분석, 피드백 수집, 회고, 기술 부채 상환 |

### 크로스커팅 유틸리티 스킬

Phase에 종속되지 않고 전체 라이프사이클에서 횡단적으로 호출 가능한 유틸리티 스킬입니다:

| 스킬 | 트리거 키워드 | 설명 | 담당 에이전트 |
|------|-------------|------|-------------|
| `sync-check` | "문서 동기화", "드리프트 체크", "코드와 문서 불일치" | 문서와 코드 사이의 불일치(Drift) 탐지 및 수정 제안 | `code-analyst` |
| `impact-analysis` | "영향 분석", "변경 영향", "임팩트 분석" | 기획/설계 변경 시 영향받는 산출물/코드/테스트 범위 분석 | `alm-manager` |
| `debt-collector` | "기술 부채 탐지", "부채 수집", "TODO 정리" | 코드 내 임시 방편(Workaround) 감지 → 부채 기록부 자동 등록 | `lead-developer` |
| `gate-keeper` | "게이트 체크", "Go/No-Go", "단계 완료 판정" | Phase 종료 시 성공 기준 충족 판정 → 다음 단계 잠금 해제 | `quality-reviewer` |

## 산출물 구조

각 단계를 진행하면 프로젝트의 `docs/` 디렉토리에 산출물이 생성됩니다:

```
your-project/
├── CLAUDE.md                   ← 에이전트 컨텍스트 파일
├── .claude/
│   └── local/                  ← gitignore 대상 작업 영역 (브랜치별 실행계획 등)
│       └── plans/
│           └── <branch>/<NN-phase>/execution-plan.md
└── docs/
    ├── lifecycle.md            ← ALM 추적 정보
    ├── tech-debt-registry.md   ← 기술 부채 기록부
    ├── kpi-definitions.md      ← 성공 지표 정의서
    ├── 00-setup/
    │   ├── project-config.md
    │   └── team-conventions.md
    ├── 01-ideation/
    │   └── idea-brief.md
    ├── 02-planning/
    │   ├── prd.md
    │   ├── user-stories.md
    │   └── scope.md
    ├── 03-architecture/
    │   ├── tech-stack.md
    │   ├── system-design.md
    │   ├── data-model.md
    │   ├── api-spec.md
    │   └── tech-debt-registry.md
    ├── 04-design/
    │   ├── sitemap.md
    │   ├── user-flows.md
    │   ├── design-system.md
    │   ├── wireframes.md
    │   └── interaction-specs/
    ├── 05-implementation/
    │   ├── conventions.md
    │   └── setup-guide.md
    ├── 06-infra/
    │   ├── infrastructure.md
    │   ├── ci-cd.md
    │   └── monitoring.md
    ├── 07-qa/
    │   ├── test-strategy.md
    │   └── release-checklist.md
    └── 08-maintenance/
        ├── monitoring-report.md
        ├── feedback-analysis.md
        ├── retrospective.md
        └── incident-reports/
```

## 핵심 원칙: Plan → Review → Execute → Re-verify

모든 Phase는 **실행계획 수립 → 검증/수락 → 실행 → 재검증**의 4단계 거버넌스 프로세스를 따릅니다. 실행계획이 수립되고 사용자의 명시적 수락을 받은 후에만 실행에 들어가며, 실행 후에는 반드시 재검증을 통해 품질을 보증합니다.

```
PLAN (실행계획서 작성) → REVIEW (사용자 검증/수락) → EXECUTE (실행) → RE-VERIFY (재검증)
                              ↓ 수정 요청 시                           ↓ 미달 시
                         PLAN으로 복귀                            보완 실행 또는
                                                              PLAN으로 복귀
```

각 Phase 진입 시 `execution-plan.md`는 **브랜치별 작업 영역**인 `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md`에 생성됩니다 (목표, 범위, 실행 단계, 성공 기준, 재검증 기준 명시). 이 영역은 `.gitignore` 처리되어 git 추적에서 제외되며, 세션이 종료되어도 디스크에 남아 다음 세션에서 이어서 사용할 수 있습니다. 합의된 계획을 영구 산출물로 보존하려면 사용자가 직접 `docs/<NN-phase>/`로 이동/복사하여 승격(promote)합니다. 자세한 규약은 `governance` 스킬 문서를 참조하세요.

## 자동 부트스트랩 (SessionStart 훅)

플러그인이 설치된 사용자 프로젝트에서 Claude Code 세션이 시작되면, 플러그인의 `SessionStart` 훅(`hooks/bootstrap-local.sh`)이 다음을 자동으로 보장합니다:

- 프로젝트 루트에 `.claude/local/plans/` 디렉토리 생성 (실행계획 작업 영역)
- 프로젝트 `.gitignore`에 `.claude/local/` 한 줄 추가 (없으면 새로 만들고, 기존 내용 보존)

이 훅은 **idempotent**합니다 — 이미 설정된 프로젝트에서는 아무 동작도 하지 않습니다. 사용자의 cwd가 git 저장소가 아니면 어떤 변경도 하지 않습니다 (보수적 가드).

훅을 비활성화했거나 외부에서 호출된 경우에도 거버넌스 PLAN 단계가 동일한 보장을 자체적으로 수행합니다.

## 사용 방법

1. 플러그인 설치 후 프로젝트 디렉토리에서 Claude Code 실행
2. `"프로젝트 설정"` 또는 `"초기 설정"`으로 Phase 0 시작 (최초 1회)
3. `"프로젝트 대시보드"` 또는 `"프로젝트 현황"`으로 전체 상태 확인
4. 원하는 단계의 키워드로 해당 단계 진행 (예: `"PRD 작성해줘"`)
5. **실행계획서를 확인하고 승인** 후 실제 실행 시작
6. 실행 완료 후 **재검증**을 통해 품질 확인
7. 각 단계의 가이드와 템플릿에 따라 산출물 생성

### 부분 사용

전체 플로우를 순서대로 진행할 필요 없이, 필요한 단계만 선택적으로 사용 가능합니다:
- "기술 스택 선정만 하고 싶어" → Phase 3만 실행
- "테스트 전략 세워줘" → Phase 7만 실행
- "PRD부터 시작하자" → Phase 2부터 시작

## 전문가 에이전트

각 단계에 해당 분야의 시니어 전문가 페르소나를 가진 에이전트가 배치되어 있습니다:

| 에이전트 | 페르소나 | 담당 Phase | 전문 영역 |
|---------|---------|-----------|----------|
| `setup-coordinator` | 프로젝트 셋업 코디네이터 | Phase 0 | 프로젝트 초기 설정, 컨벤션 정의, 환경 구성 |
| `ideation-strategist` | 이노베이션 전략가 | Phase 1 | 문제 정의, 아이디어 발산/수렴, 기회 평가 |
| `product-planner` | 시니어 프로덕트 매니저 | Phase 2 | PRD, 유저 스토리, 스코프 관리, MoSCoW, KPI |
| `system-architect` | 시니어 시스템 아키텍트 | Phase 3 | 기술 스택, 시스템 설계, DB/API 설계, ADR, 기술 부채 |
| `ux-designer` | 시니어 UX/UI 디자이너 | Phase 4 | 정보 구조, 와이어프레임, 디자인 시스템, 인터랙션 명세, 접근성 |
| `lead-developer` | 리드 개발자 | Phase 5 | 프로젝트 셋업, 코드 컨벤션, 기능 구현, 셀프 리뷰, Git 워크플로우 |
| `devops-engineer` | 시니어 DevOps/SRE | Phase 6 | Docker, CI/CD, IaC(Terraform), 클라우드, 모니터링, 보안 |
| `qa-engineer` | 시니어 QA/SDET | Phase 7 | 테스트 전략, 인수 테스트, 자동화, 성능/보안 테스트, 릴리즈 관리 |
| `sre-operator` | SRE/운영 엔지니어 | Phase 8 | 프로덕션 모니터링, 인시던트 대응, 피드백 분석, 회고 |
| `project-manager` | 테크니컬 PM | 전체 조율 | 상태 관리, 추적성, 변경 관리, 게이트 점검 |
| `alm-manager` | 어플리케이션 라이프사이클 매니저 | 전체 수명주기 | 릴리즈 전략, 기술 부채 관리, 건강도 추적, 퇴역 계획 |

### 크로스커팅 에이전트 (조사·분석·평가)

Phase에 종속되지 않고, 전체 라이프사이클에서 횡단적으로 호출 가능한 에이전트입니다:

| 에이전트 | 페르소나 | 역할 | 호출 시점 |
|---------|---------|------|----------|
| `research-analyst` | 시니어 리서치 애널리스트 | 시장/경쟁사/기술 조사, 벤치마킹, 트렌드 분석 | 모든 Phase에서 근거 자료가 필요할 때 |
| `code-analyst` | 시니어 소프트웨어 분석가 | 코드 구조/성능/보안 분석, 기술 부채 측정, 타당성 분석 | Phase 3~7에서 분석이 필요할 때 |
| `quality-reviewer` | 시니어 품질 감사관 | 산출물 완결성/정합성 평가, 크로스 리뷰, 게이트 판정 | Phase 전환 시 또는 산출물 리뷰 시 |

에이전트는 자동으로 적절한 시점에 트리거되거나, 직접 호출할 수 있습니다.

## ALM 통합

이 플러그인은 ALM 관점에서 다음을 관리합니다:

- **추적성**: 요구사항 → 설계 → 코드 → 테스트 → KPI 간의 연결
- **거버넌스**: 단계별 게이트 (Plan-Review-Execute-Reverify)
- **변경 관리**: 변경사항의 영향 분석 및 기록
- **형상 관리**: 모든 산출물의 Git 버전 관리
- **기술 부채**: 발생 기록, 추적, 정기 상환 관리
- **지속적 개선**: Phase 8 회고를 통한 프로세스 개선 순환

## 설치

```bash
claude plugin add ./project-lifecycle.plugin
```
