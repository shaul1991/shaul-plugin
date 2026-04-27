---
name: 03-architecture
description: >
  시스템 아키텍처 및 기술 설계 단계. "아키텍처 설계", "시스템 설계", "기술 스택 선정",
  "DB 설계", "API 설계", "ERD 작성", "시스템 구조", "architecture",
  "system design", "tech stack" 요청 시 사용.
metadata:
  phase: "3"
  phase_name: "아키텍처/설계"
---

# Phase 3: 아키텍처 / 설계 (Architecture)

PRD를 기반으로 기술적 의사결정을 내리고 시스템 구조를 설계한다.

## 필수: Plan → Review → Execute → Re-verify

**이 Phase를 시작하기 전에 반드시 거버넌스 프로세스를 따른다.**

1. **PLAN** — 실행계획서를 작성한다 (`governance` 스킬의 `references/execution-plan-template.md` 참조)
   - `.claude/local/plans/<sanitized-branch>/03-architecture/execution-plan.md`로 저장 (브랜치별 작업 영역, gitignore 대상)
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
- Phase 2의 `docs/02-planning/prd.md`가 존재해야 한다

## 실행 절차

### Step 1: 기술 스택 선정
PRD의 요구사항과 제약 조건을 분석하여 기술 스택을 결정한다:

1. **프론트엔드** — 프레임워크, 상태관리, UI 라이브러리
2. **백엔드** — 언어, 프레임워크, API 방식 (REST/GraphQL/gRPC)
3. **데이터베이스** — RDBMS/NoSQL/둘 다, 구체 제품
4. **인프라** — 클라우드 프로바이더, 컨테이너, 오케스트레이션
5. **기타** — 메시징, 캐시, 검색, 모니터링

각 선택에 대해 ADR (Architecture Decision Record) 형식으로 근거를 문서화:
- **Context**: 왜 이 결정이 필요한가
- **Options**: 고려한 대안들
- **Decision**: 선택한 옵션과 이유
- **Consequences**: 이 결정의 결과 (장단점)

### Step 2: 시스템 아키텍처 설계
고수준 시스템 구조를 정의한다:

1. **컴포넌트 다이어그램** — 주요 서비스/모듈과 관계 (텍스트 또는 Mermaid)
2. **데이터 흐름** — 요청-응답 흐름, 이벤트 흐름
3. **통합 포인트** — 외부 서비스, API 연동 지점
4. **배포 구조** — 환경별 (dev/staging/prod) 구성

### Step 3: 데이터 모델 설계
1. **ERD** — 엔티티 관계 다이어그램 (Mermaid erDiagram)
2. **스키마 정의** — 주요 테이블/컬렉션의 필드, 타입, 제약조건
3. **인덱스 전략** — 주요 쿼리 패턴 기반 인덱스 계획
4. **마이그레이션 전략** — 스키마 변경 관리 방법

### Step 4: API 설계
1. **엔드포인트 목록** — URL, 메서드, 설명
2. **요청/응답 스키마** — 주요 API의 입출력 형태
3. **인증/인가 흐름** — 토큰 관리, 권한 체크 포인트
4. **에러 처리 규약** — 에러 코드 체계, 응답 포맷

### Step 5: 산출물 생성
- **`docs/03-architecture/tech-stack.md`** — 기술 스택 결정 및 ADR
- **`docs/03-architecture/system-design.md`** — 시스템 구조도
- **`docs/03-architecture/data-model.md`** — ERD 및 스키마
- **`docs/03-architecture/api-spec.md`** — API 명세
- **`docs/03-architecture/tech-debt-registry.md`** — 기술 부채 기록부 (설계 시 타협 사항 기록)

## 가이드라인

- YAGNI (You Aren't Gonna Need It) — MVP에 필요한 것만 설계
- 확장 가능하되 과도한 추상화는 피한다
- "결정을 되돌릴 수 있는가?"에 따라 결정의 무게를 달리한다
  - 되돌리기 쉬운 결정 (Type 2): 빠르게 결정
  - 되돌리기 어려운 결정 (Type 1): 충분히 검토
- 다이어그램은 Mermaid 문법으로 작성하여 코드로 관리

## 참고 자료

- **`references/adr-template.md`** — ADR 작성 템플릿
- **`references/design-patterns.md`** — 일반적인 아키텍처 패턴 가이드
- **`references/tech-debt-registry-template.md`** — 기술 부채 기록부 템플릿
