---
name: 07-qa
description: >
  QA 및 테스트 단계. "테스트 전략", "QA 체크리스트", "테스트 작성",
  "통합 테스트", "E2E 테스트", "성능 테스트", "보안 테스트",
  "배포 전 점검", "qa", "testing", "quality assurance" 요청 시 사용.
metadata:
  phase: "7"
  phase_name: "QA/테스트"
---

# Phase 7: QA / 테스트 (Quality Assurance)

코드 품질을 보증하고 릴리즈 가능한 상태를 확인한다. 테스트 전략, 작성, 실행, 배포 전 최종 점검을 포함한다.

## 필수: Plan → Review → Execute → Re-verify

**이 Phase를 시작하기 전에 반드시 거버넌스 프로세스를 따른다.**

1. **PLAN** — 실행계획서를 작성한다 (`governance` 스킬의 `references/execution-plan-template.md` 참조)
   - `.claude/local/plans/<sanitized-branch>/07-qa/execution-plan.md`로 저장 (브랜치별 작업 영역, gitignore 대상)
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
- Phase 5의 코드 구현이 진행 중이거나 완료
- Phase 6의 CI 파이프라인이 기본 구성됨

## 실행 절차

### Step 1: 테스트 전략 수립
프로젝트에 맞는 테스트 피라미드를 설계:

```
        /  E2E  \          ← 적게, 핵심 플로우만
       / 통합 테스트 \       ← 중간, 서비스 간 연동
      / 단위 테스트    \     ← 많이, 빠르게 실행
     ──────────────────
```

| 테스트 유형 | 범위 | 속도 | 비율 |
|------------|------|------|------|
| 단위 테스트 | 함수/클래스 단위 | 빠름 | 70% |
| 통합 테스트 | 모듈 간 연동 | 중간 | 20% |
| E2E 테스트 | 사용자 시나리오 전체 | 느림 | 10% |

### Step 2: 단위 테스트
핵심 비즈니스 로직을 중심으로 작성:

1. **테스트 네이밍** — `describe('무엇을') > it('어떤 조건에서 어떻게 동작한다')`
2. **AAA 패턴** — Arrange(준비) → Act(실행) → Assert(검증)
3. **경계값 테스트** — 빈 값, null, 최대값, 음수 등
4. **에러 케이스** — 예외 상황, 네트워크 실패, 유효하지 않은 입력
5. **목(Mock) 사용** — 외부 의존성만 목으로 (과도한 목 지양)

커버리지 목표:
- 전체: 80% 이상
- 핵심 비즈니스 로직: 90% 이상
- 유틸리티: 90% 이상
- UI 컴포넌트: 70% 이상

### Step 3: 통합 테스트
서비스 간 연동 지점을 테스트:

1. **API 통합** — 엔드포인트 요청-응답 검증 (supertest 등)
2. **DB 통합** — 실제 DB에 대한 CRUD 검증 (testcontainers)
3. **외부 서비스** — 주요 외부 API 연동 검증 (또는 목 서버)

### Step 4: E2E 테스트
핵심 사용자 플로우만 선별하여 작성:

1. 회원가입 → 로그인 → 핵심 기능 사용 → 로그아웃
2. 결제 플로우 (있는 경우)
3. 관리자 주요 기능

도구: Playwright (권장), Cypress

### Step 5: 인수 테스트 (Acceptance Test)
Phase 2에서 정의한 기획 의도와 성공 지표(KPI)에 부합하는지 검증한다.
단순 기능 테스트를 넘어, "기획 의도대로 동작하는가"를 확인하는 단계다:

1. **유저 스토리 기반 검증** — Phase 2의 유저 스토리(`.claude/02-planning/user-stories.md`)의 Acceptance Criteria를 하나씩 확인
   - Given-When-Then으로 정의된 각 AC가 실제로 동작하는지 테스트
   - 모든 Must Have 유저 스토리의 AC가 통과해야 릴리즈 가능

2. **KPI 측정 기반 검증** — Phase 2의 KPI 정의서(`.claude/kpi-definitions.md`)에 정의된 기술 KPI 확인
   - 응답 시간 목표 달성 여부 (예: API p95 < 200ms)
   - 가용성 목표 달성 여부
   - 에러율 목표 충족 여부

3. **크로스 Phase 정합성 검증** — 각 Phase 산출물 간 일관성 확인
   | 검증 항목 | 원본 (Phase) | 구현 (Phase) | 일치 여부 |
   |----------|-------------|-------------|----------|
   | 기능 요구사항 | PRD (Phase 2) | 코드 (Phase 5) | ✅/❌ |
   | API 명세 | API Spec (Phase 3) | 실제 API (Phase 5) | ✅/❌ |
   | 디자인 명세 | 인터랙션 명세 (Phase 4) | UI 구현 (Phase 5) | ✅/❌ |
   | 인프라 구성 | 인프라 문서 (Phase 6) | 실제 구성 (Phase 6) | ✅/❌ |

4. **사용자 수용 테스트 (UAT)** — 실제 사용자 또는 이해관계자가 직접 핵심 플로우를 테스트
   - 테스트 시나리오 사전 작성
   - 발견된 이슈 분류 (Blocker / Major / Minor / Enhancement)
   - Blocker 이슈 0건이어야 릴리즈 가능

### Step 6: 비기능 테스트

**성능 테스트:**
- 부하 테스트 — 예상 동시 사용자 수의 2배 부하
- 스트레스 테스트 — 한계점 확인
- 도구: k6, Artillery

**보안 테스트:**
- OWASP Top 10 체크리스트 기반 수동 점검
- 의존성 취약점 스캔 (npm audit, Snyk)
- 인증/인가 우회 시도

### Step 7: 릴리즈 전 체크리스트
`references/release-checklist.md`를 기반으로 최종 점검:

1. 모든 테스트 통과
2. 코드 리뷰 완료
3. 문서 업데이트
4. 환경 변수 확인
5. DB 마이그레이션 준비
6. 롤백 계획 수립
7. 모니터링/알림 설정 확인

### Step 8: 산출물 생성
- **`.claude/07-qa/test-strategy.md`** — 테스트 전략 문서
- **`.claude/07-qa/release-checklist.md`** — 릴리즈 체크리스트 (실제 체크용)
- **테스트 코드** — 프로젝트 내 테스트 디렉토리

## 가이드라인

- 테스트는 독립적이어야 한다 — 실행 순서에 의존하지 않음
- 테스트 데이터는 각 테스트에서 생성/정리 (fixture/factory 패턴)
- Flaky 테스트는 즉시 수정하거나 격리 — 신뢰도가 생명
- 커버리지 숫자보다 의미 있는 테스트가 중요
- CI에서 자동 실행, 실패 시 머지 차단
- 회귀 테스트 — 버그 수정 시 해당 버그를 재현하는 테스트 먼저 작성

## 참고 자료

- **`references/release-checklist.md`** — 릴리즈 전 상세 체크리스트
- **`references/test-patterns.md`** — 테스트 작성 패턴 및 안티패턴
- Phase 2 유저 스토리(`.claude/02-planning/user-stories.md`)와 KPI 정의서(`.claude/kpi-definitions.md`)를 참조하여 인수 테스트를 수행한다
