# 사내 3종 문서(용어집·기획요구·기술요구) 통합 관리 헌장

- **작성일**: 2026-04-28
- **반영 출시**: v0.6.0
- **관련 커밋**: (출시 시 추가)
- **상태**: Active
- **상위 헌장**: `2026-04-28-claude-output-charter.md`(v0.4.0), `2026-04-28-stack-registration-charter.md`(v0.5.0)
- **연계 조사 노트**: `docs/plans/2026-04-28-three-doc-set-and-domain-agent-research.md`

## 사용자 원문 요구사항

세션 중 사용자가 보낸 메시지를 시간순으로 보존한다(의역·축약 최소화).

### (1) 초기 질문
> 플러그인을 사용하는 프로젝트에서 도메인/비즈니스 용어 등은 어떻게 문서를 관리하고 설정할 수 있는가?

### (2) 의도 명료화 — 외부 조사 우선
> 외부 도구·표준 조사 먼저.
> (DDD 풀세트 / 글로벌 표준은 보류, 평면적 용어집 수준)

### (3) 의도 명료화 — 회사 내부 용도
> 모든 글로벌한 표준을 만들거나 따르고 싶은건 아니다 회사내에서 사용하는
> 용어나 공유할 용어를 정의해서 플러그인 및 AI사용, 온보딩 시 싱크를
> 맞추기 위한것이다.

### (4) 소비자 범위
> 용어집을 읽는 대상은 프로젝트 한정이며, 프로젝트를 유지보수 관리하는
> 사람과 AI(claude code, cursor, 타 AItools), claude code memory 등이다.

### (5) 산출물 카테고리 확정
> 사내 용어정리 문서 / 기획적 요구사항 / 기술적 요구사항 이렇게 3가지의
> 문서가 필요하다.

### (6) 신규 에이전트 추가 요구
> 이러한 팀별 및 도메인 등 사이간의 소통을 담당하는 전문 agent를 같이
> 하나 계획하라.

### (7) 7개 결정 (조사 노트 §8 답변)
1. Q1 — 인덱스+3산출물로 진행. 단 *필요시 인덱스를 먼저 확인*하고, 필요한 산출물만 확인. 3개 산출물을 *먼저 함께 읽지 않는다*.
2. Q2 — `.claude/knowledge/` 신설, 그 아래 3 산출물.
3. Q3 — 루트 `AGENTS.md` 권장.
4. Q4 — 머신 미러 보류.
5. Q5 — SessionStart 훅은 (c) 매니페스트 변경처럼 *특정 트리거 변경 시 갱신 검토 권고*.
6. Q6 — 신규 에이전트 작명 `domain-liaison`.
7. Q7 — 권장사항: gate-keeper 행 *유지* + 검증 실행을 `domain-liaison`에 위임.

## 도출한 원칙 (6개)

1. **3종 문서는 한 묶음으로 다룬다.** 사내 용어집·기획요구·기술요구는 항상 함께 등록·갱신·승격된다. 어느 하나만 따로 배포하거나 갱신하는 경로를 만들지 않는다.
2. **인덱스가 진입점, lazy-load 가 기본.** AI/사용자는 *항상 `.claude/knowledge/index.md` 부터* 읽는다. 인덱스가 가리키는 3 산출물은 *필요할 때만* 읽는다. 컨텍스트·토큰 절약과 온보딩 가독성을 동시에 만족한다.
3. **모든 산출물은 `.claude/knowledge/` 안에서 시작.** 기존 `.claude/02-planning/`, `.claude/03-architecture/` 와 *분리된 별도 영역*. phase 산출물은 그 자체로 유지되고, knowledge 는 그것들을 *요약·매개*하는 별도 문서다.
4. **승격은 사용자 결정, 권장은 루트 `AGENTS.md`.** 다중 AI 도구(Codex/Cursor/Copilot/Gemini 등) 도달을 위해서는 사용자가 인덱스를 루트 `AGENTS.md` 로 *직접 이동·심링크* 하는 것을 권장. 플러그인은 *어떤 경우에도 `AGENTS.md` 를 자동 생성·수정·승격하지 않는다.* (claude-output-charter 원칙 5 정합)
5. **머신 미러는 v0.6.0 에서 보류.** 사람 가독 마크다운만 작성. 단, SessionStart 훅의 변경 감지를 위한 *최소 watch 메타데이터*(파일 경로 + sha256)는 `.claude/local/knowledge-watch.json` 에 둔다. 이는 *콘텐츠 미러가 아니다* — 변경 감지 베이스라인일 뿐.
6. **변경 감지는 알림만, 결정은 사용자.** SessionStart 훅이 3 산출물의 sha256 변동을 감지하면 *알리기*만 하고, 어떤 자동 갱신·재정렬·재인덱싱도 하지 않는다. (stack-registration-charter 원칙 4 정합)

## 설계 결정

| ID | 결정 | 근거 |
|----|------|------|
| D1 | 신규 크로스커팅 스킬 `knowledge` 신설(phase 독립) | 사용자 답변 Q2. 3종 문서가 phase 산출물과 분리된 *별도 묶음*임을 구조에 반영. 트리거 키워드: "용어집", "온보딩 문서", "knowledge" 등. |
| D2 | 신규 에이전트 `domain-liaison` 신설 | 사용자 답변 Q6. 14 → 15 에이전트. 페르소나는 조사 노트 §6 드래프트. |
| D3 | 산출물 4개: `.claude/knowledge/index.md`, `glossary.md`, `product-requirements.md`, `technical-requirements.md` | 사용자 답변 Q1+Q2. 인덱스 + 3 산출물 구조. |
| D4 | 인덱스는 *링크/요약*만, 본문은 3 산출물에 둔다 (lazy-load) | 사용자 답변 Q1 단서 — "필요시 인덱스를 먼저 확인하고, 필요한 산출물을 확인. 3개 산출물을 먼저 함께 확인하지 않는다." |
| D5 | 루트 `AGENTS.md` 는 *권장만*. 자동 생성·수정 X. 사용자가 `ln -s .claude/knowledge/index.md AGENTS.md` 또는 직접 이동 | 사용자 답변 Q3. claude-output-charter 원칙 5(도구 비종속). |
| D6 | 머신 미러(JSON) 보류 | 사용자 답변 Q4. tech-stack 의 두 거울 패턴은 *명확한 머신 사용처가 있을 때*만 의미. knowledge 는 사용처가 아직 명확하지 않음 — 과대 설계 회피. |
| D7 | SessionStart 훅 `knowledge-watch.sh` 추가 | 사용자 답변 Q5(c). stack-watch.sh 와 같은 슬롯에 추가, 같은 패턴(읽기/sha256 비교/알림). |
| D8 | 변경 감지 베이스라인은 `.claude/local/knowledge-watch.json` (파일 경로 + sha256 만) | 원칙 5. *콘텐츠 미러가 아니다.* 머신 미러 보류와 정합. |
| D9 | `gate-keeper` 의 "용어 일관성" 행 유지 + `domain-liaison` 에 검증 위임 | 사용자 답변 Q7 권장 채택. 게이트 표는 한 곳에 모이고, 콘텐츠 책임은 콘텐츠 오너에게. quality-reviewer 와 phase 에이전트의 분리 패턴 계승. |
| D10 | 02-planning, 03-architecture SKILL 본문은 *수정하지 않는다*(이번 라운드) | knowledge 는 phase 산출물의 *요약/매개*일 뿐, phase 자체를 변경하지 않는다. 인덱스→phase 산출물 링크 패턴이면 충분. 향후 필요 시 별도 라운드. |
| D11 | 플러그인·마켓플레이스 버전 v0.5.0 → v0.6.0 | 신규 스킬·에이전트·훅 도입 — minor 버전 업. SemVer breaking 없음(기존 산출물 그대로 동작). |

## 미래 변경 시 지킬 것

이 헌장은 후속 변경에 대한 **불변 가드레일**이다. 위반 시 본 문서를 먼저 갱신하거나(=원칙 변경의 근거 기록) 설계를 바꾼다.

1. **자동 외부 쓰기 금지.** `AGENTS.md` 자동 생성·갱신·심링크 생성 코드를 만들지 않는다. 사용자의 *수동 동작* 외에는 외부 영역에 닿지 않는다.
2. **인덱스가 SSOT.** 3 산출물 중 어느 하나가 별도로 외부 도구 컨텍스트에 직접 등록되도록 권장하지 않는다. 항상 인덱스를 거친다.
3. **lazy-load 강제.** AI 가 인덱스 없이 3 산출물을 자동으로 모두 읽도록 만들지 않는다. 인덱스 → 필요한 1~2 산출물만 읽는다. SKILL 절차에 명시.
4. **자동 추측 금지.** 코드에서 식별자를 채굴해 글로서리에 자동 등록하는 경로를 만들지 않는다(stack-registration-charter 원칙 1 계승). 모든 항목은 사용자 입력에서.
5. **자동 갱신 금지.** SessionStart 훅이 3 산출물 또는 인덱스를 *쓰는* 경로를 만들지 않는다. 훅의 책임은 *읽고 알리는* 것까지.
6. **머신 미러 도입은 사용처가 먼저.** v0.7+ 에서 머신 미러를 도입한다면, 그 미러를 *읽는* 명확한 사용처(예: `sync-check`이 글로서리 ↔ 코드 매칭)가 함께 도입되어야 한다. 미러만 추가하는 변경은 거부.
7. **다른 AI 도구 폴더 자동 쓰기 금지.** `.cursor/`, `.codex/`, `.gemini/`, `.github/copilot-instructions.md` 등에 본 플러그인이 직접 쓰는 통합을 만들지 않는다. claude-output-charter 원칙 5 직접 계승.

## 관련 문서

- `CHANGELOG.md` `[0.6.0]` 항목 — 출시 내역 및 마이그레이션
- `claude-code-plugin/project-lifecycle/skills/knowledge/SKILL.md` — 본 헌장의 절차적 구현
- `claude-code-plugin/project-lifecycle/agents/domain-liaison.md` — 신규 에이전트 정의
- `claude-code-plugin/project-lifecycle/hooks/knowledge-watch.sh` — SessionStart 변경 감지 훅
- `docs/plans/2026-04-28-three-doc-set-and-domain-agent-research.md` — 본 헌장의 외부 조사 입력
- `docs/direction/2026-04-28-claude-output-charter.md` — 상위 출력 단일성 헌장
- `docs/direction/2026-04-28-stack-registration-charter.md` — 사용자 입력 우선·변경 감지 패턴 형제 헌장
