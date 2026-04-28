# 기술적 요구사항 요약 (Technical Requirements)

- **프로젝트**: <프로젝트명>
- **마지막 갱신**: YYYY-MM-DD
- **상위 인덱스**: [`./index.md`](./index.md)
- **출처 원본 (전체 본문)**: `.claude/03-architecture/tech-stack.md`, `system-design.md`, `data-model.md`, `api-spec.md`
- **머신 미러 (스택만)**: `.claude/local/stack.json` (v0.5.0 부터)

> 이 문서는 기술 결정의 *요약*이다. ADR 본문은 출처 원본을 본다(lazy-load).

## 작성 규칙

- 핵심 결정 3~7개로 압축. 각 항목 2~4문장.
- 모든 항목에 *출처 섹션 링크*를 반드시 첨부.
- 용어집의 단어를 그대로 사용한다.
- 자동 추측 금지(stack-charter 원칙 1 계승) — 모든 항목은 사용자 입력에서.

## 핵심 기술 결정

### T1. 언어·프레임워크
- **요약 (2~4문장)**: 예) "백엔드는 PHP 8.2 + Laravel 11 단일 스택. 모노레포 X. 프론트엔드는 별도 저장소(외부 위탁) — 본 저장소 범위 밖."
- **출처**: [`tech-stack.md#언어`](../03-architecture/tech-stack.md), [`stack.json`](../local/stack.json)
- **관련 용어집 항목**: (해당 없음 — 기술 식별자는 글로서리에 등록하지 않는 것이 일반적)

### T2. 데이터 저장소
- **요약**: 예) "MySQL 8 (운영 RDS) + Redis (세션·큐). NoSQL 미사용. 데이터 정합성 우선."
- **출처**: [`tech-stack.md#DB`](../03-architecture/tech-stack.md), [`data-model.md`](../03-architecture/data-model.md)
- **관련 용어집 항목**: 회원(Member), 결제(Payment) — 주요 엔티티

### T3. API 스타일
- **요약**: 예) "REST + JSON. GraphQL 미도입. 인증은 OAuth2 Bearer Token."
- **출처**: [`api-spec.md`](../03-architecture/api-spec.md)
- **관련 용어집 항목**: ...

### T4. 인프라·배포
- **요약**: ...
- **출처**: [`infrastructure.md`](../06-infra/infrastructure.md), [`ci-cd.md`](../06-infra/ci-cd.md)
- **관련 용어집 항목**: ...

## 비결정 (Deferred / Open)

| 항목 | 사유 | 결정 예정 |
|---|---|---|
| GraphQL 도입 | 현 단계 ROI 낮음 | v1.1 검토 |
| Kafka 도입 | 트래픽 부족 | v1.2 검토 |

## 갱신 이력

| 일자 | 항목 | 변경 유형 | 사유 |
|---|---|---|---|
| YYYY-MM-DD | T1~T4 | 추가 | 초기 등록 |
