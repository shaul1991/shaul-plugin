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
| `knowledge` (v0.6.0) | "용어집", "사내 용어", "온보딩 문서", "기획 요구", "기술 요구" | 사내 3종 문서(용어집·기획요구·기술요구)를 인덱스 + 3 산출물 lazy-load 구조로 관리. 루트 `AGENTS.md` 권장 승격 가이드 포함. | `domain-liaison` |
| `codex-reviewer` (v0.8.0) | (사용자 트리거 없음 — 07-qa Step 0 디스패처가 호출) | 외부 OpenAI Codex CLI 를 Bash 로 호출해 Phase 산출물을 평가하는 *백엔드* 스킬. `quality-reviewer` 와 동일한 평가 프레임워크 사용. | (스킬 단독 — 전용 에이전트 없음) |

## 산출물 구조

플러그인이 만드는 모든 산출물은 프로젝트의 **`.claude/` 폴더 안**에만 생성되며, `.claude/` 전체가 기본적으로 `.gitignore` 처리됩니다. 프로젝트 루트와 `docs/`는 사용자의 영역으로 그대로 비어 있습니다.

```
your-project/
├── .gitignore                  ← `.claude/` 한 줄 자동 등록
├── docs/                       ← 사용자 영역 (플러그인 미관여)
└── .claude/                    ← 폴더 전체 ignore (기본값)
    ├── CLAUDE.md               ← 에이전트 컨텍스트 (Claude Code가 자동 로드)
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
    │   ├── tech-stack.md          ← 사람 가독 ADR (사용자 입력 기반)
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
    ├── 08-maintenance/
    │   ├── monitoring-report.md
    │   ├── feedback-analysis.md
    │   ├── retrospective.md
    │   └── incident-reports/
    ├── knowledge/              ← 사내 3종 문서 (v0.6.0+, lazy-load 진입점은 index.md)
    │   ├── index.md
    │   ├── glossary.md
    │   ├── product-requirements.md
    │   └── technical-requirements.md
    └── local/                  ← 브랜치별 실행계획 작업 영역
        ├── plans/
        │   └── <branch>/<NN-phase>/execution-plan.md
        ├── stack.json          ← 머신 가독 미러 (tech-stack.md 와 1대1)
        └── knowledge-watch.json ← 변경 감지 베이스라인 (sha256 만, 콘텐츠 미러 X)
```

### 산출물 공유 (사용자 결정에 의한 추적)

`.claude/` 전체가 ignore되므로 플러그인 산출물은 기본적으로 git에 포함되지 않습니다. 팀과 공유하고 싶은 산출물(예: PRD, 유저 스토리)이 생기면 **사용자가 해당 파일을 `.claude/` 밖으로 직접 이동**시키면 됩니다 — 이동된 파일은 자연스럽게 git 추적 대상이 됩니다.

```bash
# 예: PRD를 docs/로 옮겨 팀과 공유하기
mkdir -p docs/02-planning
git mv .claude/02-planning/prd.md docs/02-planning/prd.md
```

`git add -f`나 `!.claude/...` un-ignore 패턴도 가능하지만, 플러그인 권장 방식은 단순 이동입니다. 추적 여부는 전적으로 사용자 결정입니다.

### v0.3.x → v0.4.0 마이그레이션

기존 사용자는 다음을 한 번 수행하면 v0.4.0 레이아웃으로 이전할 수 있습니다:

```bash
# 1. .claude/ 폴더 준비
mkdir -p .claude

# 2. docs/ 산출물을 .claude/로 이동
for d in 00-setup 01-ideation 02-planning 03-architecture 04-design \
         05-implementation 06-infra 07-qa 08-maintenance; do
  [ -d "docs/$d" ] && git mv "docs/$d" ".claude/$d"
done
git mv docs/lifecycle.md docs/tech-debt-registry.md docs/kpi-definitions.md .claude/ 2>/dev/null || true

# 3. 루트의 CLAUDE.md를 .claude/로 이동
[ -f CLAUDE.md ] && git mv CLAUDE.md .claude/CLAUDE.md

# 4. .gitignore의 .claude/local/ 라인은 SessionStart 훅이 자동으로 .claude/로 교체합니다 (수동 작업 불필요)

# 5. 추적이 필요한 산출물(예: PRD)은 다시 .claude/ 밖으로 꺼내면 됩니다
#    git mv .claude/02-planning/prd.md docs/02-planning/prd.md
```

`.editorconfig` 자동 생성은 v0.4.0에서 제거되었습니다. 필요하면 `references/team-conventions-template.md`의 샘플 스니펫을 참고해 직접 루트에 만드세요.

## 핵심 원칙: Plan → Review → Execute → Re-verify

모든 Phase는 **실행계획 수립 → 검증/수락 → 실행 → 재검증**의 4단계 거버넌스 프로세스를 따릅니다. 실행계획이 수립되고 사용자의 명시적 수락을 받은 후에만 실행에 들어가며, 실행 후에는 반드시 재검증을 통해 품질을 보증합니다.

```
PLAN (실행계획서 작성) → REVIEW (사용자 검증/수락) → EXECUTE (실행) → RE-VERIFY (재검증)
                              ↓ 수정 요청 시                           ↓ 미달 시
                         PLAN으로 복귀                            보완 실행 또는
                                                              PLAN으로 복귀
```

각 Phase 진입 시 `execution-plan.md`는 **브랜치별 작업 영역**인 `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md`에 생성됩니다 (목표, 범위, 실행 단계, 성공 기준, 재검증 기준 명시). 이 영역은 `.claude/` 폴더 전체 ignore의 일부로 git 추적에서 제외되며, 세션이 종료되어도 디스크에 남아 다음 세션에서 이어서 사용할 수 있습니다. 합의된 계획을 영구 산출물로 보존하려면 사용자가 직접 `.claude/<NN-phase>/`로 이동시키고, 팀 공유가 필요하면 그 산출물을 `.claude/` 밖(예: `docs/<NN-phase>/`)으로 한 번 더 이동시켜 추적 영역에 둡니다. 자세한 규약은 `governance` 스킬 문서를 참조하세요.

## 자동 부트스트랩 (SessionStart 훅)

플러그인이 설치된 사용자 프로젝트에서 Claude Code 세션이 시작되면, 플러그인의 `SessionStart` 훅이 세 단계로 동작합니다:

### 1) `bootstrap-local.sh` — 작업 영역 보장
- 프로젝트 루트에 `.claude/local/plans/` 디렉토리 생성 (실행계획 작업 영역)
- 프로젝트 `.gitignore`에 `.claude/` 한 줄 추가 (없으면 새로 만들고, 기존 내용 보존)
- 레거시 `.claude/local/` 라인은 자동으로 `.claude/`로 교체 (v0.3.x → v0.4.0 무중단 업그레이드)

### 2) `stack-watch.sh` — 기술 스택 컨텍스트 주입 + 변경 감지
- `.claude/local/stack.json` 이 **없으면** "기술 스택이 등록되지 않았습니다 — `/03-architecture` 로 등록하세요" 한 줄 안내. 자동으로 묻거나 추측하지 않습니다.
- 있으면 등록된 각 프로젝트의 *요약(언어 + 프레임워크)* 을 모델 컨텍스트에 주입해 후속 단계가 사용자 스택을 인지하도록 합니다.
- 등록 시점 대비 매니페스트(`composer.json`, `pyproject.toml`, `requirements.txt`)의 sha256 이 달라졌으면 *변경 알림*을 추가로 주입하고 `/03-architecture` 갱신 검토를 권장합니다. 자동 갱신은 하지 않습니다.

### 3) `knowledge-watch.sh` — 사내 3종 문서 변경 감지 (v0.6.0+)
- `.claude/local/knowledge-watch.json` 이 **없으면** 조용히 종료(인덱스만 있고 베이스라인이 없으면 `/knowledge` 호출 권유 한 줄).
- 있으면 4 파일(`index.md`, `glossary.md`, `product-requirements.md`, `technical-requirements.md`)의 sha256 을 등록 시점 베이스라인과 비교해, 변경된 항목이 있으면 *알림*만 모델 컨텍스트에 주입하고 `/knowledge` 갱신 검토를 권장합니다. 자동 갱신은 하지 않습니다.
- 베이스라인 파일은 *콘텐츠 미러가 아닙니다* — 경로 + sha256 만 담는 변경 감지 메타데이터. 머신 미러는 v0.6.0 에서 보류(헌장 D6).

`.claude/` 전체가 ignore되므로 플러그인 산출물은 기본적으로 git에 포함되지 않습니다. 세 훅 모두 **idempotent** 하고 *읽기/추가만* 합니다 — 이미 설정된 프로젝트에서는 부작용이 없습니다. 사용자의 cwd가 git 저장소가 아니면 어떤 변경도 하지 않습니다 (보수적 가드).

훅을 비활성화했거나 외부에서 호출된 경우에도 거버넌스 PLAN 단계가 동일한 보장을 자체적으로 수행합니다.

## 시크릿 파일 가드 (v0.7.0)

플러그인은 `Read`/`Edit`/`Write`/`Bash` 도구가 시크릿 파일을 만지려 시도할 때 **무조건** 차단하거나 사용자에게 묻습니다. 어느 step·skill·에이전트에서 호출되든 동일하게 적용됩니다(skill 별 우회 경로 없음).

### 동작 방식 — `PreToolUse` 훅 (`secret-guard.sh`)

세션 시작이 아니라 *각 도구 호출 직전*에 동작합니다.

- **차단 (`always_block`)** → `permissionDecision: "deny"` + exit 2. Claude Code 가 도구를 실행하지 않습니다.
- **묻기 (`ask_before_read`)** → `permissionDecision: "ask"`. 사용자에게 인라인 프롬프트가 떠서 확인 후 진행.
- **통과** → 무출력 + exit 0.

### 사용자 정책 — `.claude/secret-guard.json` (직접 편집)

```json
{
  "schema_version": 1,
  "always_block": [".env", ".env.*"],
  "ask_before_read": [],
  "exempt_suffixes": [".example", ".sample", ".template", ".dist"]
}
```

- 매칭은 *basename* 기준 fnmatch 글롭(`*`, `?`, `[..]`).
- 두 카테고리 동시 매치 시 우선순위: `always_block` > `ask_before_read`.
- `exempt_suffixes` 는 양 카테고리 공통 적용(매치되더라도 이 접미사로 끝나면 통과).
- 정책 파일이 *없으면* 위 스키마와 동일한 내장 기본값이 적용됩니다.
- 시작 샘플: `claude-code-plugin/project-lifecycle/hooks/secret-guard-template.json` 을 `.claude/secret-guard.json` 으로 복사 후 편집.

### Bash 명령어 검사

`Bash` 도구는 `command` 인자를 토큰화해 각 토큰의 basename 으로 검사합니다. `cat .env`, `source .env`, `grep KEY .env`, `cp .env /tmp/` 등은 모두 차단됩니다. `cat .env.example` 처럼 템플릿 접미사는 통과합니다.

### 일시 해제 (Opt-out)

```bash
CLAUDE_PLUGIN_SECRET_GUARD=off claude
```

허용 값(대소문자 무관): `off`, `0`, `false`, `no`. 그 외 모든 값은 활성으로 간주.
세션 단위·명시적·트레이스 가능. 우회 시 stderr 에 알림 한 줄. 세션 종료 시 자동 복원.

### Fail-closed 동작

다음 상황에서는 *허용이 아닌 차단*(deny + exit 2) 으로 폐쇄적으로 동작합니다 — 보안 가드는 평가 불가 시 안전한 쪽을 택합니다:
- 시스템에 `python3` 가 없을 때
- stdin 의 tool-call JSON 이 비어있거나 파싱 실패
- 정책 파일(`.claude/secret-guard.json`) 자체 파싱 실패는 *내장 기본값으로 폴백*(fail-closed 아님 — 안전 기본값이 있어서). 단 *필드 타입 오류*(예: `always_block: "string"`)는 해당 필드만 기본값으로 폴백.

복구 경로: python3 설치, 정책 파일 수정, 또는 `CLAUDE_PLUGIN_SECRET_GUARD=off` 한시 우회.

상세 원칙은 `docs/direction/2026-04-28-secret-file-guardrail-charter.md` 헌장을 참조하세요.

## 리뷰 백엔드 선택 (v0.8.0)

Phase 7 QA 리뷰를 어느 백엔드로 수행할지 사용자가 선택할 수 있습니다. **기본값은 `claude`** (인-프로세스 `quality-reviewer` 에이전트) — 정책 파일이 없으면 v0.7.x 와 정확히 동일하게 동작합니다.

### 백엔드 선택지

| `reviewer` | 동작 | 사전 조건 | 산출물 |
|---|---|---|---|
| `claude` | 세션 안에서 `quality-reviewer` 에이전트가 평가 (기존 v0.7.x 경로) | 없음 | `.claude/reviews/<phase>-claude-<ts>.md` |
| `codex` | Bash 로 외부 `codex` CLI 호출 후 stdout 캡처 | `codex` 설치 + `codex login` | `.claude/reviews/<phase>-codex-<ts>.md` (헤더 5줄: backend·model·exit·ts·hash) |
| `cross` | Claude → Codex 순차 실행 + 비교 파일 생성 | codex 설치 권장 (미설치 시 `claude` 만 실행 후 안내) | 위 두 파일 + `.claude/reviews/<phase>-cross-<ts>.md` (항목별 일치/불일치 표) |

### 해석 우선순위

`07-qa` 스킬 Step 0 디스패처가 다음 순서로 *resolved backend* 를 결정하고 한국어로 announce 합니다:

1. 환경변수 `CLAUDE_PLUGIN_REVIEWER` (`claude` / `codex` / `cross`)
2. `.claude/review-config.json` 의 `per_phase_overrides["07"]` → `reviewer`
3. 내장 기본값 `claude`

### 사용자 정책 — `.claude/review-config.json` (직접 편집)

```json
{
  "schema_version": 1,
  "reviewer": "claude",
  "codex": {
    "model": "",
    "timeout_sec": 300,
    "extra_flags": []
  },
  "per_phase_overrides": {}
}
```

- 시작 샘플: `claude-code-plugin/project-lifecycle/hooks/review-config-template.json` 을 `.claude/review-config.json` 으로 복사 후 편집.
- `codex.timeout_sec` 미지정 시 기본 300초. 환경변수 `CODEX_TIMEOUT` 으로도 일시 조정 가능.
- `_writer_reserved` 키는 미래 PR 슬롯 (코드 작성 백엔드 분기). v0.8.0 에서는 미사용 — 무시하면 됩니다.

### 일시 변경 (Opt-in)

```bash
CLAUDE_PLUGIN_REVIEWER=codex claude    # 이번 세션만 codex 백엔드
CLAUDE_PLUGIN_REVIEWER=cross claude    # 이번 세션만 cross 백엔드
CLAUDE_PLUGIN_REVIEWER=claude claude   # 정책 파일이 codex 여도 claude 강제
```

### Cross 모드 — 사람이 최종 판정

두 백엔드의 판정이 다를 때 *자동 차단하지 않습니다*. 비교 파일에 두 결과를 나란히 보여주고, "사람의 최종 판정" 섹션을 사용자가 직접 채웁니다. 이는 LLM 비결정성과 두 모델의 강점이 다르다는 점을 인정하는 사용자 결정 정책입니다.

### 시크릿 가드 상호작용

`codex` 호출은 PreToolUse Bash 훅(secret-guard)을 그대로 통과합니다. 프롬프트는 `.claude/local/codex/<phase>-<ts>.prompt.md` 파일에 먼저 기록한 뒤 codex 에 *파일 경로/stdin* 으로 전달하므로(인라인 heredoc 금지), `.env` 류 토큰이 명령줄에 노출되지 않습니다. 프롬프트 본문에 시크릿이 포함되어 있다면 secret-guard 가 차단하며, 이는 정상 동작입니다 — 우회하지 마세요.

### 실패 모드

| 상황 | 동작 |
|---|---|
| `codex` 미설치 | "codex CLI 미설치 — Claude 리뷰로 폴백" 안내 후 `quality-reviewer` 자동 호출 |
| 인증 누락 (stderr 에 `auth`/`login`) | 폴백 없이 중단. "`codex login` 후 재시도" 안내 (사용자 액션 필요) |
| 타임아웃 | 중단 + Claude 폴백 권유. `CODEX_TIMEOUT` env 로 조정 가능 |
| 그 외 비-제로 종료 | stderr 노출 후 사용자 판단 (재시도 / Claude 폴백 / 중단) |
| Verdict 라인 누락 | 결과 파일 그대로 저장 + "사람이 직접 확인 필요" 경고 추가 |

## 기술 스택 등록 & 갱신 (v0.5.0)

03-architecture 스킬은 사용자 프로젝트의 기술 스택을 **사용자 입력 기반**으로 등록·갱신합니다. 플러그인은 매니페스트(`composer.json` 등)를 *읽어 추측하지 않습니다* — 모든 정보는 사용자 입력에서 옵니다.

### 등록 모드 (최초 실행)

`/03-architecture` 호출 → SKILL 이 워크스페이스 구조와 각 프로젝트의 언어·프레임워크를 묻습니다. 다중 프로젝트(모노레포)면 프로젝트별로 따로 입력합니다(예: `apps/api` = PHP+Laravel, `services/jobs` = Python+FastAPI). 사용자가 확인하면 두 산출물이 *동시에* 작성됩니다:

- `.claude/03-architecture/tech-stack.md` — 사람 가독 ADR (권위 있는 결정)
- `.claude/local/stack.json` — 머신 가독 미러 (다른 단계와 SessionStart 훅이 읽음)

### 갱신 모드 (이후 실행)

`stack.json` 이 이미 있으면 SKILL 이 *갱신 모드*로 진입해, 현재 등록 내용을 표로 보여주고 항목별로 *변경/유지/삭제/추가* 를 묻습니다. SessionStart 훅이 매니페스트 변경을 감지했으면 그 항목이 강조됩니다. 자동 갱신은 없습니다 — 모든 결정은 사용자가 합니다.

### 1차 자동 변경 감지 범위 (v0.5.0)

| 언어 | 프레임워크 | watched 매니페스트 |
|------|----------|-------------------|
| PHP | Laravel | `composer.json` |
| Python | FastAPI | `pyproject.toml`, `requirements.txt` |

그 외 언어/프레임워크도 ADR 에 자유롭게 등록할 수 있습니다 — 단지 자동 변경 감지가 적용되지 않을 뿐입니다(`watched_manifests: []`). 갱신은 사용자가 `/03-architecture` 를 다시 호출해 수행합니다.

상세 원칙은 `docs/direction/2026-04-28-stack-registration-charter.md` 헌장을 참조하세요.

## 사내 3종 문서 통합 관리 (v0.6.0)

`knowledge` 스킬은 사내에서 *플러그인 + AI 도구 + 신규 입사자(사람)* 사이의 싱크를 위한 3종 문서를 묶어 관리합니다. **lazy-load 원칙**: 항상 인덱스부터 읽고, 3 산출물은 *필요할 때만* 펼칩니다.

### 산출물

```
.claude/
├── knowledge/
│   ├── index.md                       ← 진입점 (lazy-load)
│   ├── glossary.md                    ← 사내 평면 용어집
│   ├── product-requirements.md        ← 기획적 요구사항 요약
│   └── technical-requirements.md      ← 기술적 요구사항 요약
└── local/
    └── knowledge-watch.json           ← 변경 감지 베이스라인 (sha256 만, 콘텐츠 미러 X)
```

### 등록 모드 (최초 실행)

`/knowledge` 호출 → SKILL 이 소비자(어느 AI 도구가 읽을지) 확인 후 3종 입력 받기 → 4 파일 동시 작성 → 변경 감지 베이스라인 저장. 모든 항목은 *사용자 입력에서* 오며 추측하지 않습니다.

### 갱신 모드 (이후 실행)

`index.md` 가 이미 있으면 *갱신 모드*로 진입해 인덱스만 먼저 표시하고, 사용자가 갱신 대상을 지정해야 해당 산출물이 펼쳐집니다(lazy-load). SessionStart 훅이 변경된 파일을 강조합니다. 자동 갱신은 없습니다.

### 다른 AI 도구 도달 — 루트 `AGENTS.md` 권장 (수동 승격)

플러그인은 *어떤 경우에도* `AGENTS.md` 를 자동 생성·수정하지 않습니다(헌장 원칙 5 — 도구 비종속). 다중 AI 도구(Cursor, Codex CLI, Copilot, Gemini, Aider 등) 도달이 필요하면 사용자가 직접:

```bash
# 옵션 A: 심볼릭 링크 (Unix/Mac, Windows는 git config core.symlinks=true)
ln -s .claude/knowledge/index.md AGENTS.md
git add AGENTS.md && git commit -m "chore: link AGENTS.md to knowledge index"

# 옵션 B: 직접 이동
git mv .claude/knowledge/index.md AGENTS.md
```

도구별 자동 로드 경로와 권장 설정은 `skills/knowledge/SKILL.md` Step 5 또는 `references/index-template.md` §5 참조.

### 도메인 연락관 에이전트 (`domain-liaison`)

15번째 에이전트로 신설. 3종 문서 상호 참조 일관성 유지, 기획↔기술 vocabulary 통역·중재, 신규 입사자 온보딩 가이드 청지기. `gate-keeper` 의 "용어 일관성" 검증을 위임받습니다. 글로서리가 미등록인 프로젝트에서는 *⚠️ N/A — knowledge 미등록* 으로 표기됩니다.

상세 원칙은 `docs/direction/2026-04-28-three-doc-set-charter.md` 헌장을 참조하세요.

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
| `domain-liaison` (v0.6.0) | 시니어 도메인 연락관 | 사내 3종 문서 상호 참조 일관성, 기획↔기술 vocabulary 통역·중재, 신규 입사자 온보딩 청지기 | `knowledge` 스킬 호출 시, 02-/03- Phase 종료 후, gate-keeper "용어 일관성" 위임 |

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
