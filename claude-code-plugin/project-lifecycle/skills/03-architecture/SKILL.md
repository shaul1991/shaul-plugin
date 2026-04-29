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
- Phase 2의 `.claude/02-planning/prd.md`가 존재해야 한다

## 실행 절차

### Step 1: 기술 스택 등록 또는 갱신 (사용자 입력 우선)

> **운영 원칙**: 플러그인은 사용자 프로젝트의 언어/프레임워크를 *자동으로 추측하지 않는다.* 모든 정보는 사용자 입력에서 온다. SKILL 은 그 입력을 정형화·기록하는 보조 역할만 한다.

먼저 `.claude/local/stack.json` 의 존재 여부를 확인해 *등록 모드(1-A)* 와 *갱신 모드(1-B)* 를 분기한다.

#### 1-A. 등록 모드 (`.claude/local/stack.json` 이 없을 때)

1. **워크스페이스 구조 입력**: 사용자에게 묻는다 — 단일 프로젝트인가, 다중 프로젝트(모노레포)인가? 다중 프로젝트면 각 프로젝트의 디렉터리 경로(예: `apps/api`, `services/jobs`).
2. **각 프로젝트별 입력**:
   - 언어와 버전 (예: `php 8.2`, `python 3.12`)
   - 프레임워크와 버전 (예: `laravel 11.x`, `fastapi 0.110.x`)
   - 주요 인프라/라이브러리(DB, 메시지큐, 캐시 등) — 선택
3. **요약 확인**: 입력값을 표로 다시 보여주고 사용자의 *명시적 확인*을 받는다 ("위와 같이 등록하시겠습니까?").
4. **두 파일 동시 작성** (1대1 거울):
   - 사람 가독 ADR — `.claude/03-architecture/tech-stack.md` (다중 프로젝트면 프로젝트별 섹션)
   - 머신 가독 미러 — `.claude/local/stack.json` (스키마는 `references/stack-json-template.json`)
5. **watched_manifests 작성** (1차 자동 변경 감지 범위):
   - PHP+Laravel 인 프로젝트는 `composer.json`
   - Python+FastAPI 인 프로젝트는 `pyproject.toml` 또는 `requirements.txt` 중 실제 존재하는 것
   - 그 외 언어/프레임워크는 `watched_manifests: []` 로 비워둔다 (사용자가 직접 갱신 호출).
   - 각 매니페스트의 `sha256` 은 *현재 파일 바이트의 sha256* 을 기록. 매니페스트가 아직 없으면 해당 항목 자체를 생략.

#### 1-B. 갱신 모드 (이미 `.claude/local/stack.json` 이 있을 때)

1. **현재 등록 내용 표시**: 기존 stack.json 을 읽어 표로 제시.
2. **변경 항목 강조**: SessionStart hook(`stack-watch.sh`) 이 보고한 변경 매니페스트가 있으면 그 항목을 강조해 보여준다.
3. **항목별 결정**: 사용자에게 *변경/유지/삭제/추가*를 묻는다. 자동 갱신은 하지 않는다.
4. **두 파일 갱신**:
   - `tech-stack.md` 의 해당 섹션 갱신 또는 추가/삭제
   - `stack.json` 의 `projects[]` 갱신, `watched_manifests` 의 sha256 도 *현재 파일 바이트의 sha256* 으로 새로 계산, `updated_at` 갱신

#### 등록·갱신 시 ADR 작성 원칙

각 결정(언어, 프레임워크, 주요 인프라)에 대해 ADR 형식으로 근거를 문서화한다:
- **Context**: 왜 이 결정이 필요한가
- **Options**: 고려한 대안들
- **Decision**: 선택한 옵션과 이유
- **Consequences**: 이 결정의 결과 (장단점)

다중 프로젝트면 ADR 도 프로젝트별 섹션(`## Project: apps/api`, `## Project: services/jobs`)으로 분리한다.

#### 카테고리 체크리스트 (각 프로젝트 입력 시 참고)

1. **프론트엔드** — 프레임워크, 상태관리, UI 라이브러리
2. **백엔드** — 언어, 프레임워크, API 방식 (REST/GraphQL/gRPC)
3. **데이터베이스** — RDBMS/NoSQL/둘 다, 구체 제품
4. **인프라** — 클라우드 프로바이더, 컨테이너, 오케스트레이션
5. **기타** — 메시징, 캐시, 검색, 모니터링

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

> **원칙**: API 명세는 *처리 로직·개념·설계의 기록*이다. request/response 형태는 변경되기 쉬우므로 자세히 굳히지 않는다 — 대신 "왜 이렇게 처리하는가", "어떤 흐름을 타는가"를 남긴다.

각 API(또는 API 그룹)별로 다음을 기록한다 (중요도 순):

1. **처리 로직 & 핵심 개념** (필수, 중요도 ★★★)
   - 이 API가 풀려는 문제와 책임 범위
   - 핵심 도메인 개념 / 비즈니스 룰 / 불변식
   - 알고리즘 또는 처리 단계 (의사코드 가능)

2. **동기 / 비동기 처리** (필수, 중요도 ★★★)
   - 동기 처리인가, 큐/이벤트 기반 비동기인가
   - 비동기면 트리거·큐·워커·완료 통지 메커니즘
   - 응답 시점(즉시 vs accepted-then-poll)과 idempotency 키

3. **인프라 흐름도** (필수, 중요도 ★★★)
   - 클라이언트 → 게이트웨이 → 서비스 → DB / 캐시 / 큐 / 외부 API 까지의 호출 경로
   - Mermaid `sequenceDiagram` 또는 `flowchart` 권장
   - 타임아웃·리트라이·서킷브레이커가 걸리는 지점 표시

4. **외부 API 호출** (해당 시 필수, 중요도 ★★★)
   - 호출하는 외부 시스템과 엔드포인트
   - 인증 방식, rate limit, 타임아웃 정책
   - 실패 시 폴백 전략 (재시도·대체 경로·degrade)

5. **주의사항 & 트레이드오프** (필수, 중요도 ★★☆)
   - 동시성 / 경합 / 락 고려사항
   - 보안·프라이버시 주의점 (PII, 권한 경계)
   - 알려진 한계, 향후 개선 여지

6. **인증 / 인가 흐름** (해당 시 필수, 중요도 ★★☆)
   - 토큰 종류, 만료, 갱신 흐름
   - 권한 체크 지점 (route guard / service layer / data layer)

7. **엔드포인트 목록** (요약 수준, 중요도 ★☆☆)
   - URL, 메서드, 한 줄 설명
   - request/response 의 *상세 스키마는 작성하지 않는다* — 변경 빈도가 높아 문서가 코드와 어긋나기 쉽다. 실제 스키마는 코드(타입·OpenAPI 어노테이션)를 단일 진실로 둔다.

8. **에러 처리 규약** (간단, 중요도 ★☆☆)
   - 에러 코드 체계 / 공통 응답 포맷의 *원칙*만 기록
   - 개별 에러 메시지 카탈로그는 코드에 둔다

> ⚠️ request/response 본문은 *예시 1~2개*까지만 둔다. 그 이상은 코드를 정답으로 본다.

작성 시 `references/api-spec-template.md` 의 골격을 복사해 채운다.

### Step 5: 산출물 생성
- **`.claude/03-architecture/tech-stack.md`** — 기술 스택 결정 및 ADR (사람 가독, 권위 있는 결정)
- **`.claude/local/stack.json`** — `tech-stack.md` 와 1대1 거울인 머신 가독 미러. 후속 단계(05-implementation, 06-infra 등)와 SessionStart 훅(`stack-watch.sh`)이 읽는다. 스키마는 `references/stack-json-template.json`
- **`.claude/03-architecture/system-design.md`** — 시스템 구조도
- **`.claude/03-architecture/data-model.md`** — ERD 및 스키마
- **`.claude/03-architecture/api-spec.md`** — API 명세
- **`.claude/03-architecture/tech-debt-registry.md`** — 기술 부채 기록부 (설계 시 타협 사항 기록)

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
- **`references/api-spec-template.md`** — API 명세 템플릿 (Step 4 산출물용, 처리 로직·설계 중심)
- **`references/tech-debt-registry-template.md`** — 기술 부채 기록부 템플릿
- **`references/stack-json-template.json`** — `.claude/local/stack.json` 스키마 v1 예시 (다중 프로젝트 포함)
