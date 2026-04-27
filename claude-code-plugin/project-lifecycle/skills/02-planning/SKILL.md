---
name: 02-planning
description: >
  프로젝트 기획 단계. "기획서 작성", "PRD 작성", "요구사항 정의", "스코프 정의",
  "기능 목록", "유저 스토리 작성", "프로젝트 기획", "planning",
  "product requirements" 요청 시 사용.
metadata:
  phase: "2"
  phase_name: "기획"
---

# Phase 2: 기획 (Planning)

아이디어를 구체적인 제품 요구사항으로 전환한다. PRD, 유저 스토리, 스코프 정의를 포함한다.

## 필수: Plan → Review → Execute → Re-verify

**이 Phase를 시작하기 전에 반드시 거버넌스 프로세스를 따른다.**

1. **PLAN** — 실행계획서를 작성한다 (`governance` 스킬의 `references/execution-plan-template.md` 참조)
   - `.claude/local/plans/<sanitized-branch>/02-planning/execution-plan.md`로 저장 (브랜치별 작업 영역, gitignore 대상)
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

## 전제 조건
- Phase 1 (아이디어 수집)의 `docs/01-ideation/idea-brief.md`가 존재해야 한다
- 없을 경우 사용자에게 Phase 1 먼저 진행할지 또는 간략 요약으로 대체할지 확인

## 실행 절차

### Step 1: 요구사항 수집
아이디어 브리프를 기반으로 상세 요구사항을 도출한다:

1. **기능 요구사항 (Functional)** — 시스템이 무엇을 해야 하는가
2. **비기능 요구사항 (Non-Functional)** — 성능, 보안, 확장성, 접근성
3. **제약 조건** — 기술적, 비즈니스적, 법적 제약
4. **가정 사항** — 전제하는 조건들
5. **성공 지표(KPI)** — 이 프로젝트의 성공을 측정할 핵심 지표 정의

### Step 2: 유저 스토리 작성
각 기능 요구사항을 유저 스토리로 변환:

```
As a [사용자 유형],
I want to [행위],
So that [기대 가치].

Acceptance Criteria:
- Given [전제조건], When [행위], Then [결과]
```

우선순위를 MoSCoW 방법으로 분류:
- **Must Have**: 없으면 출시 불가
- **Should Have**: 중요하지만 우회 가능
- **Could Have**: 있으면 좋음
- **Won't Have (this time)**: 이번 스코프에서 제외

### Step 3: 스코프 정의
MVP (Minimum Viable Product) 범위를 확정한다:

1. Must Have 항목만으로 MVP 스코프 구성
2. 릴리즈 단계별 로드맵 작성 (MVP → v1.0 → v1.1 → ...)
3. 각 단계의 예상 기간과 마일스톤 정의

### Step 4: 산출물 생성
아래 파일들을 생성한다:

- **`docs/02-planning/prd.md`** — `references/prd-template.md` 기반
- **`docs/02-planning/user-stories.md`** — 유저 스토리 목록
- **`docs/02-planning/scope.md`** — 스코프 및 마일스톤

## 가이드라인

- PRD는 "왜"와 "무엇"에 집중 — "어떻게"는 설계 단계에서
- 기능 하나당 유저 스토리 하나 이상 작성
- Acceptance Criteria는 테스트 가능하게 작성
- 초기에 지나치게 세밀하게 쓰지 않는다 — iterative하게 보강
- 비기능 요구사항(성능, 보안)을 빠뜨리지 않도록 체크리스트 활용

## 참고 자료

- **`references/prd-template.md`** — PRD 템플릿
- **`references/nfr-checklist.md`** — 비기능 요구사항 체크리스트
- **`references/kpi-template.md`** — 성공 지표(KPI) 정의 템플릿
