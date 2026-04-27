---
name: 00-setup
description: >
  프로젝트 초기 설정 및 컨텍스트 로딩 단계. "프로젝트 설정", "초기 설정",
  "프로젝트 시작", "환경 설정", "컨벤션 정의", "프로젝트 초기화",
  "setup", "project init", "context loading" 요청 시 사용.
metadata:
  phase: "0"
  phase_name: "초기 설정"
---

# Phase 0: 초기 설정 (Setup & Context Loading)

프로젝트를 시작하기 전, 에이전트가 일관성 있게 작동하기 위한 기본 룰과 환경을 세팅한다.
모든 Phase에 앞서 수행되어야 하며, 프로젝트의 "헌법"에 해당한다.

## 필수: Plan → Review → Execute → Re-verify

**이 Phase를 시작하기 전에 반드시 거버넌스 프로세스를 따른다.**

1. **PLAN** — 실행계획서를 작성한다 (`governance` 스킬의 `references/execution-plan-template.md` 참조)
   - 해당 Phase의 `docs/` 디렉토리에 `execution-plan.md`로 저장
   - 목표, 범위, 실행 단계, 성공 기준을 구체적으로 기술
2. **REVIEW** — 실행계획서를 사용자에게 제시하고 명시적 수락을 받는다
   - 승인(Approved) → 실행 절차로 진행
   - 수정 요청(Revise) → 계획 수정 후 재검증
   - 거부(Rejected) → 근본적 재설계
3. **EXECUTE** — 수락된 계획에 따라 아래 실행 절차를 수행한다
4. **RE-VERIFY** — 실행 완료 후 산출물과 결과를 재검증한다
   - 성공 기준 대비 달성 여부 확인
   - 산출물 완결성 및 이전 Phase와의 정합성 검증
   - 교훈(Lessons Learned) 기록
   - 통과(Pass) → 다음 Phase 진행 / 미달(Fail) → 보완 실행 또는 계획 재수립

> ⚠️ 실행계획 수립과 수락 없이 실행에 들어가지 않는다. 실행 후 재검증 없이 다음 Phase로 넘어가지 않는다.

## 실행 절차

### Step 1: 프로젝트 메타데이터 정의
프로젝트의 기본 정보를 정의한다:

1. **프로젝트명** — 공식 이름, 코드네임 (있을 경우)
2. **프로젝트 유형** — 웹앱, 모바일앱, API, 라이브러리, CLI 도구 등
3. **팀 구성** — 역할별 인원 (또는 1인 프로젝트)
4. **타임라인** — 대략적 일정, 마일스톤 기한
5. **주요 이해관계자** — 의사결정자, 리뷰어, 최종 사용자

### Step 2: 개발 환경 컨벤션 설정
팀(또는 개인)의 작업 규칙을 정의한다:

1. **프로그래밍 언어 및 런타임** — 버전 포함 (예: Node.js 20, Python 3.12)
2. **패키지 매니저** — npm, pnpm, yarn, pip, poetry 등
3. **코드 스타일** — Prettier, ESLint, Black, Ruff 등 도구와 규칙
4. **Git 전략** — GitHub Flow, Git Flow, Trunk-based 중 선택
5. **커밋 규칙** — Conventional Commits 사용 여부 및 타입 정의
6. **브랜치 네이밍** — `feature/`, `fix/`, `chore/` 등 접두사 규칙
7. **문서 언어** — 한국어/영어/혼합

### Step 3: 프로젝트 구성 파일 생성
에이전트가 참조할 프로젝트 구성 파일을 생성한다:

1. **`CLAUDE.md`** — 에이전트에게 프로젝트 컨텍스트를 전달하는 핵심 파일
   - 프로젝트 개요, 기술 스택, 디렉토리 구조, 코딩 컨벤션 요약
2. **`.editorconfig`** — 에디터 공통 설정 (들여쓰기, 줄바꿈 등)
3. **`.gitignore`** — 버전 관리 제외 파일 목록
4. **`docs/` 디렉토리 초기화** — lifecycle.md 생성

### Step 4: ALM 추적 파일 초기화
프로젝트 수명주기 추적을 위한 기본 파일을 생성한다:

1. **`docs/lifecycle.md`** — Phase별 진행 이력, 게이트 판정, 변경 이력
2. **`docs/tech-debt-registry.md`** — 기술 부채 기록부 초기화
3. **`docs/kpi-definitions.md`** — 성공 지표 정의 문서 초기화

### Step 5: 산출물 생성
- **`docs/00-setup/project-config.md`** — 프로젝트 메타데이터 및 컨벤션
- **`docs/00-setup/team-conventions.md`** — 팀 컨벤션 상세
- **`CLAUDE.md`** — 프로젝트 루트의 에이전트 컨텍스트 파일
- **`docs/lifecycle.md`** — ALM 추적 파일
- **`docs/tech-debt-registry.md`** — 기술 부채 기록부
- **`docs/kpi-definitions.md`** — 성공 지표 정의서

## 가이드라인

- Phase 0은 다른 모든 Phase의 전제 조건이다 — 반드시 먼저 수행
- CLAUDE.md는 프로젝트 진행에 따라 지속적으로 업데이트해야 한다
- 컨벤션은 처음에 정하고, 변경 시 반드시 팀 합의를 거친다
- 1인 프로젝트라도 컨벤션을 문서화한다 — 미래의 자신을 위해
- "나중에 정하자"는 가장 비싼 선택 — 초기 10분 투자가 이후 10시간을 절약한다

## 참고 자료

- **`references/project-config-template.md`** — 프로젝트 설정 템플릿
- **`references/team-conventions-template.md`** — 팀 컨벤션 정의 템플릿
