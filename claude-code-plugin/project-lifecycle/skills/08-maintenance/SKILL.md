---
name: 08-maintenance
description: >
  운영, 유지보수 및 회고 단계. "운영 모니터링", "에러 분석", "사용자 피드백",
  "회고", "포스트모템", "유지보수", "버그 분석", "성능 최적화",
  "maintenance", "post-mortem", "retrospective" 요청 시 사용.
metadata:
  phase: "8"
  phase_name: "운영/회고"
---

# Phase 8: 운영 및 회고 (Maintenance & Post-mortem)

릴리즈 이후의 지속적인 개선 단계. 에러 분석, 사용자 피드백 수집, 성능 모니터링,
프로젝트 회고를 통해 제품의 품질을 지속적으로 향상시킨다.
ALM의 진정한 완성은 '종료'가 아니라 '지속적인 개선'에 있다.

## 필수: Plan → Review → Execute → Re-verify

**이 Phase를 시작하기 전에 반드시 거버넌스 프로세스를 따른다.**

1. **PLAN** — 실행계획서를 작성한다 (`governance` 스킬의 `references/execution-plan-template.md` 참조)
   - `.claude/local/plans/<sanitized-branch>/08-maintenance/execution-plan.md`로 저장 (브랜치별 작업 영역, gitignore 대상)
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
- Phase 7의 릴리즈 체크리스트가 통과됨
- 프로덕션 배포가 완료됨
- 모니터링 시스템이 구성됨 (Phase 6)

## 실행 절차

### Step 1: 프로덕션 모니터링 체계 점검
릴리즈 후 초기 안정화 기간의 모니터링 계획:

1. **헬스체크 대시보드** — 핵심 지표 실시간 확인
   - 응답 시간 (p50, p95, p99)
   - 에러율 (4xx, 5xx)
   - 리소스 사용률 (CPU, 메모리, 디스크)
   - 활성 사용자 수
2. **알림 임계치 정의** — 각 지표의 Warning/Critical 기준
3. **온콜 로테이션** — 대응 담당자 및 에스컬레이션 경로

### Step 2: 에러 로그 분석
프로덕션 에러를 체계적으로 분석:

1. **에러 분류 체계**
   | 심각도 | 정의 | 대응 시간 | 예시 |
   |--------|------|----------|------|
   | P0 (Critical) | 서비스 전면 장애 | 즉시 | 서버 다운, 데이터 유실 |
   | P1 (Major) | 핵심 기능 장애 | 4시간 내 | 결제 실패, 로그인 불가 |
   | P2 (Minor) | 일부 기능 장애 | 24시간 내 | UI 깨짐, 부분 오류 |
   | P3 (Low) | 미미한 영향 | 다음 스프린트 | 오타, UX 개선점 |

2. **에러 추적 프로세스**
   ```
   에러 감지 → 분류(P0~P3) → 원인 분석 → 수정 → 배포 → 검증
                                ↓
                       반복 발생 시 Root Cause Analysis
   ```

3. **Root Cause Analysis (RCA)** — 5 Whys 또는 Fishbone 다이어그램 활용

### Step 3: 사용자 피드백 수집 및 분석
정량적/정성적 피드백을 체계적으로 수집:

1. **정량적 피드백**
   - 사용자 행동 분석 (페이지뷰, 전환율, 이탈률)
   - Phase 2에서 정의한 KPI 대비 실적 측정
   - NPS(Net Promoter Score) 또는 CSAT(Customer Satisfaction)

2. **정성적 피드백**
   - 사용자 인터뷰, 서포트 티켓 분석
   - 앱 스토어 리뷰, 소셜 미디어 반응
   - 피드백 분류: 버그 / 기능 요청 / UX 개선 / 성능

3. **피드백 → 백로그 변환**
   ```
   피드백 수집 → 분류 → 우선순위 부여 (RICE/ICE) → 백로그 등록
                                                    ↓
                                            다음 스프린트 기획에 반영
   ```

### Step 4: 기술 부채 리뷰
Phase 3에서 시작된 기술 부채 기록부를 정기적으로 리뷰:

1. **기술 부채 현황 점검** — `docs/tech-debt-registry.md` 리뷰
2. **신규 부채 등록** — 운영 중 발견된 새로운 기술 부채 추가
3. **부채 상환 우선순위** — 비즈니스 임팩트 기준으로 정렬
4. **상환 계획** — 다음 스프린트에 상환할 부채 선정 (전체 작업의 10-20%)

### Step 5: 프로젝트 회고 (Retrospective)
`references/retrospective-template.md`를 기반으로 회고를 진행:

1. **What went well?** — 잘한 점
2. **What didn't go well?** — 부족했던 점
3. **What to improve?** — 개선할 점
4. **Action items** — 구체적 실행 과제 (담당자, 기한 포함)

회고 주기:
| 규모 | 주기 | 참여자 |
|------|------|--------|
| 스프린트 회고 | 매 스프린트 | 개발팀 |
| 릴리즈 회고 | 매 릴리즈 | 전체 팀 |
| 분기 회고 | 분기별 | 전체 팀 + 이해관계자 |

### Step 6: 인시던트 포스트모템
장애 발생 시 `references/incident-analysis-template.md`로 포스트모템 작성:

1. **타임라인** — 장애 발생부터 해결까지 시간순 기록
2. **영향 범위** — 영향받은 사용자 수, 서비스, 기간
3. **근본 원인** — 직접 원인 + 근본 원인
4. **대응 과정** — 감지, 대응, 해결, 검증 과정
5. **재발 방지** — 구체적 예방 조치 (담당자, 기한 포함)

### Step 7: 산출물 생성
- **`docs/08-maintenance/monitoring-report.md`** — 모니터링 현황 보고서
- **`docs/08-maintenance/feedback-analysis.md`** — 피드백 분석 결과
- **`docs/08-maintenance/retrospective.md`** — 회고 기록
- **`docs/08-maintenance/incident-reports/`** — 인시던트 포스트모템 (발생 시)
- **`docs/tech-debt-registry.md`** 업데이트 — 기술 부채 현황 갱신

## 가이드라인

- Phase 8은 "일회성"이 아닌 **지속적으로 반복**되는 Phase다
- 포스트모템은 Blameless(비난 없이) — 사람이 아닌 시스템/프로세스를 개선
- KPI는 Phase 2에서 정의한 성공 지표와 연결하여 측정
- 기술 부채는 무시하면 복리로 증가한다 — 정기적 상환 필수
- "완벽한 릴리즈는 없다" — 피드백 루프를 빠르게 돌리는 것이 핵심
- 회고 없는 반복은 같은 실수의 반복이다

## 참고 자료

- **`references/retrospective-template.md`** — 회고 템플릿
- **`references/incident-analysis-template.md`** — 인시던트 분석 템플릿
