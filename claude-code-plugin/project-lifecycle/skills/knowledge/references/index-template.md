# 프로젝트 지식 인덱스 (Knowledge Index)

> **읽기 안내**: 이 인덱스가 진입점입니다. 필요한 산출물 *하나*만 더 펼쳐서 읽으세요.
> 3 산출물을 한꺼번에 모두 읽지 마세요(lazy-load 원칙).

- **프로젝트**: <프로젝트명>
- **마지막 갱신**: YYYY-MM-DD
- **작성 책임**: `domain-liaison` 에이전트 + 사용자
- **상위 헌장**: `docs/direction/2026-04-28-three-doc-set-charter.md`

---

## 1. 사내 용어집 (Glossary)

> 이 프로젝트에서 *팀 공통으로 쓰는 용어*들이 정의되어 있다. 새 단어를 만나면 여기를 먼저 본다.

- **본문**: [`glossary.md`](./glossary.md)
- **항목 수**: N개 (등록일 기준)
- **요약 (1~2문장)**: 예) "본 프로젝트는 결제·배송 도메인의 핵심 용어 12개를 정의하며, 비즈니스/개발이 같은 표현을 쓰도록 한다."

### 주요 용어 빠른 인덱스 (가나다순 / A-Z 혼합)
- 결제 (Payment) — `glossary.md#결제`
- 배송 (Delivery) — `glossary.md#배송`
- 회원 (Member) — `glossary.md#회원`
- ...

---

## 2. 기획적 요구사항 (Product Requirements)

> 이 프로젝트가 *왜* 만들어지는가, *무엇을* 푸는가의 핵심.

- **본문**: [`product-requirements.md`](./product-requirements.md)
- **출처 원본 (전체)**: `.claude/02-planning/prd.md`, `user-stories.md`, `scope.md`
- **요약 (1~2문장)**: 예) "MVP 는 결제 + 배송의 단일 흐름을 검증한다. KPI 는 D+30 결제 완료율 30%."

### 핵심 의도 빠른 인덱스
- M1: <제목> — `product-requirements.md#m1`
- M2: <제목> — `product-requirements.md#m2`
- ...

---

## 3. 기술적 요구사항 (Technical Requirements)

> 이 프로젝트를 *어떻게* 만드는가의 핵심 기술 결정.

- **본문**: [`technical-requirements.md`](./technical-requirements.md)
- **출처 원본 (전체)**: `.claude/03-architecture/tech-stack.md`, `system-design.md`, `data-model.md`, `api-spec.md`
- **요약 (1~2문장)**: 예) "PHP 8.2 + Laravel 11 + MySQL 8 + Redis 단일 백엔드. 모노레포 X."

### 핵심 결정 빠른 인덱스
- T1: <제목> — `technical-requirements.md#t1`
- T2: <제목> — `technical-requirements.md#t2`
- ...

---

## 4. 상호 참조 노트 (Cross-Reference)

`domain-liaison` 가 갱신 시 점검·기록하는 1~3 줄 노트:

- 글로서리 항목과 PRD/기술요구의 표현이 일치하는가? (예: "결제" 단일 용어 사용, "구매"·"결제" 혼용 없음)
- 기획↔기술 vocabulary 충돌은 없는가?
- 신규 입사자가 *이 인덱스만 읽고* 진입점을 찾을 수 있는가?

---

## 5. 다른 AI 도구에서 이 인덱스를 읽게 하려면 (권장)

> 플러그인은 다른 AI 도구의 폴더에 *자동으로 쓰지 않는다*. 아래는 사용자 결정 가이드.

권장: 루트 `AGENTS.md` 로 승격(이동 또는 심링크). `knowledge` 스킬 §Step 5 참조.

| 도구 | 자동 로드 경로 | 한 번 설정할 것 |
|---|---|---|
| Claude Code | `.claude/CLAUDE.md` | 본문에 `@knowledge/index.md` |
| Codex CLI | `AGENTS.md` (루트) | 심링크 또는 이동 |
| Cursor | `.cursor/rules/*.mdc` | `.mdc` 본문에서 `AGENTS.md` 참조 |
| GitHub Copilot | `.github/copilot-instructions.md` | "see AGENTS.md" 한 줄 |
| Gemini CLI | `~/.gemini/GEMINI.md` | settings 의 `context.fileName` 에 `AGENTS.md` 추가 |
| Aider | (자동 X) | `.aider.conf.yml` 의 `read: AGENTS.md` |
