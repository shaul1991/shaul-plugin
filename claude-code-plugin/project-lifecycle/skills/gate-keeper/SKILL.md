---
name: gate-keeper
description: >
  Phase 게이트 판정 스킬. 각 Phase 종료 시 성공 기준 충족 여부를 객관적으로 판정하여
  다음 단계 진행(Go) 또는 보완(No-Go)을 결정한다. "게이트 체크", "단계 완료 판정",
  "다음 단계 가능?", "게이트 키퍼", "Go/No-Go", "gate check",
  "phase gate", "품질 게이트" 요청 시 사용.
metadata:
  phase: "cross-cutting"
  phase_name: "품질 게이트"
  linked_agent: "quality-reviewer"
---

# 품질 게이트 판정 (Gate Keeper)

각 Phase 종료 시 성공 기준 충족 여부를 객관적으로 판정하여,
다음 Phase로의 전이를 승인(Go)하거나 보완을 요구(No-Go/Iterate)한다.

> **담당 에이전트**: `quality-reviewer` (시니어 품질 감사관)

## 왜 필요한가

Phase를 "대충 넘기고" 다음으로 가면, 나중에 되돌아와야 할 때 비용이 기하급수적으로 증가한다.
Gate Keeper는 각 Phase의 "최소 품질 문턱"을 지키는 파수꾼이다.
엄격하지만 공정하게, 객관적 기준으로 판정한다.

## 실행 절차

### Step 1: 게이트 체크 대상 확인
어떤 Phase의 게이트를 점검할지 결정한다:

```
현재 Phase: Phase N
실행계획서 위치: .claude/local/plans/<sanitized-branch>/NN-xxx/execution-plan.md
성공 기준: 실행계획서 §7 (Success Criteria)
재검증 기준: 실행계획서 §8 (Re-verification Criteria)
```

### Step 2: 산출물 완결성 검증
해당 Phase의 필수 산출물이 모두 존재하는지 확인한다:

**Phase별 필수 산출물 체크리스트:**

| Phase | 필수 산출물 | 존재 여부 |
|-------|-----------|----------|
| 0 | project-config.md, team-conventions.md, CLAUDE.md, lifecycle.md | ✅/❌ |
| 1 | idea-brief.md | ✅/❌ |
| 2 | prd.md, user-stories.md, scope.md, kpi-definitions.md | ✅/❌ |
| 3 | tech-stack.md, system-design.md, data-model.md, api-spec.md, tech-debt-registry.md | ✅/❌ |
| 4 | sitemap.md, user-flows.md, design-system.md, wireframes.md, interaction-specs | ✅/❌ |
| 5 | conventions.md, setup-guide.md, 프로젝트 코드, 셀프 리뷰 완료 | ✅/❌ |
| 6 | infrastructure.md, ci-cd.md, monitoring.md, Dockerfile, CI/CD 설정 | ✅/❌ |
| 7 | test-strategy.md, release-checklist.md, 테스트 코드, 인수 테스트 결과 | ✅/❌ |
| 8 | monitoring-report.md, feedback-analysis.md, retrospective.md | ✅/❌ |

### Step 3: 성공 기준 대조
실행계획서의 성공 기준(§7)을 하나씩 확인한다:

```markdown
## 성공 기준 검증 결과

| # | 성공 기준 | 충족 여부 | 근거 | 비고 |
|---|----------|----------|------|------|
| 1 | [기준 1] | ✅ Pass / ❌ Fail / ⚠️ Partial | | |
| 2 | [기준 2] | ✅ Pass / ❌ Fail / ⚠️ Partial | | |
| 3 | [기준 3] | ✅ Pass / ❌ Fail / ⚠️ Partial | | |
```

### Step 4: 정합성 검증
현재 Phase의 산출물이 이전 Phase 산출물과 일관되는지 확인한다:

**크로스 Phase 정합성 체크:**
| 검증 항목 | 원본 | 현재 | 일치 여부 |
|----------|------|------|----------|
| 기능 범위 | PRD (Phase 2) | 현재 산출물 | ✅/❌ |
| 기술 결정 | tech-stack (Phase 3) | 현재 산출물 | ✅/❌ |
| 용어 일관성 | 전체 docs | 현재 산출물 | ✅/❌ |

### Step 5: 품질 평가
산출물의 품질을 정성적으로 평가한다:

| 품질 기준 | 등급 (A~D) | 설명 |
|----------|-----------|------|
| 완결성 (Completeness) | | 필수 항목이 모두 포함되었는가 |
| 명확성 (Clarity) | | 모호하지 않고 이해 가능한가 |
| 실행 가능성 (Actionability) | | 다음 Phase에서 바로 활용 가능한가 |
| 추적 가능성 (Traceability) | | 이전 Phase 산출물과 연결되는가 |
| 일관성 (Consistency) | | 산출물 내부 및 산출물 간 모순이 없는가 |

### Step 6: 게이트 판정
종합 판정을 내린다:

**판정 기준:**

| 판정 | 조건 | 다음 행동 |
|------|------|----------|
| **Go** (통과) | 모든 성공 기준 Pass + 정합성 통과 + 품질 B 이상 | 다음 Phase 진행 가능 |
| **Conditional Go** (조건부 통과) | 성공 기준 대부분 Pass + Minor 이슈만 존재 | 경미한 보완 후 통과 (재점검 불필요) |
| **Iterate** (보완 필요) | 일부 성공 기준 Fail 또는 품질 C | 부분 보완 후 재점검 |
| **No-Go** (미통과) | 핵심 성공 기준 Fail 또는 품질 D | 해당 Phase 재실행 (실행계획 재수립 포함) |

### Step 7: 게이트 판정서 작성

```markdown
# Gate Review — Phase N: [Phase명]

## 판정 요약
| 항목 | 결과 |
|------|------|
| 판정일 | YYYY-MM-DD |
| 판정자 | quality-reviewer |
| 최종 판정 | **Go / Conditional Go / Iterate / No-Go** |
| 성공 기준 달성 | N/N (Pass/Total) |
| 산출물 완결성 | N/N |
| 정합성 | Pass / Fail |
| 품질 등급 | A / B / C / D |

## 필요 조치 (Conditional Go / Iterate / No-Go 시)
| # | 조치 사항 | 심각도 | 예상 소요 |
|---|----------|--------|----------|
| 1 | | Major/Minor | |
| 2 | | | |

## 교훈 (Lessons Learned)
-
-
```

### Step 8: 산출물
- **게이트 판정서** — `docs/NN-xxx/gate-review.md`
- **lifecycle.md 업데이트** — 게이트 판정 이력 기록
- (Conditional Go 시) 보완 사항 목록

## 트리거 시점

- **자동 트리거** — 각 Phase의 Re-verify 단계에서 자동 호출
- **수동 트리거** — "Phase N 게이트 체크해줘", "다음 단계 넘어가도 돼?"
- **스킵 불가** — Phase 전환 시 게이트 판정은 필수 (거버넌스 규칙)

## 가이드라인

- 게이트는 "검열"이 아닌 "품질 보증" — 프로젝트를 보호하는 안전장치
- 100% 완벽을 요구하지 않는다 — "충분히 좋은가"를 판단
- Conditional Go를 적극 활용한다 — 사소한 이슈로 전체를 막지 않음
- No-Go는 드물어야 하지만, 필요하다면 단호하게 — 늦은 발견보다 빠른 발견이 낫다
- 게이트 판정은 기록으로 남긴다 — 나중에 "왜 이때 넘어갔지?"에 대한 답이 된다
- 반복적으로 Iterate가 나온다면 이전 Phase의 품질 또는 실행계획의 성공 기준을 재검토
