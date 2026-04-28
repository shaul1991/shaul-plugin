---
name: knowledge
description: >
  사내 3종 문서(용어집·기획요구·기술요구) 통합 관리 스킬. 인덱스(`.claude/knowledge/index.md`)
  진입점과 3 산출물(`glossary.md`, `product-requirements.md`, `technical-requirements.md`)을
  사용자 입력 기반으로 등록·갱신한다. lazy-load 원칙: 항상 인덱스부터 확인하고 필요한 산출물만 읽는다.
  "용어집", "사내 용어", "온보딩 문서", "기획 요구", "기술 요구", "프로젝트 지식 정리",
  "knowledge", "glossary", "AGENTS.md 권장" 요청 시 사용.
metadata:
  phase: "cross-cutting"
  phase_name: "지식 관리"
  linked_agent: "domain-liaison"
---

# 지식 관리 (Knowledge — 3종 문서 통합)

사내에서 *플러그인 + AI 도구(Cursor·Codex·Gemini·Copilot 등) + 신규 입사자(사람)* 사이의 싱크를 맞추기 위한 3종 문서를 통합 관리한다. 모든 산출물은 `.claude/knowledge/` 안에서 시작하며, git 추적 승격(루트 `AGENTS.md` 권장)은 사용자 결정으로만 일어난다.

> **담당 에이전트**: `domain-liaison` (도메인 연락관)
> **상위 헌장**: `docs/direction/2026-04-28-three-doc-set-charter.md`

## 핵심 원칙 (헌장 요약)

1. **3종은 한 묶음** — 용어집·기획요구·기술요구는 항상 함께 등록·갱신·승격.
2. **lazy-load** — 항상 인덱스(`index.md`)부터 읽는다. 3 산출물은 *필요할 때만* 펼친다.
3. **`.claude/knowledge/` 단일 시작 영역** — `02-planning/`, `03-architecture/` 와 분리된 별도 묶음(요약·매개 역할).
4. **루트 `AGENTS.md` 는 권장만, 자동 생성 X** — 사용자 수동 이동·심링크.
5. **머신 미러 보류** — 사람 가독 마크다운만. SessionStart 훅의 *변경 감지 베이스라인*은 `.claude/local/knowledge-watch.json` (콘텐츠 미러 아님).
6. **변경 감지는 알림만, 결정은 사용자.**

## 필수: Plan → Review → Execute → Re-verify

이 스킬은 phase 독립 크로스커팅이지만, 거버넌스 4단계는 동일하게 따른다.

1. **PLAN** — 실행계획서를 `.claude/local/plans/<sanitized-branch>/knowledge/execution-plan.md`에 작성.
2. **REVIEW** — 사용자 명시적 수락.
3. **EXECUTE** — 아래 등록/갱신 절차.
4. **RE-VERIFY** — 인덱스가 3 산출물을 모두 가리키는지, 3 산출물이 lazy-load 조각화 가능한 길이인지 점검.

## 실행 절차

### Step 0: 모드 분기

먼저 `.claude/knowledge/index.md` 의 존재 여부로 *등록 모드(0-A)* 와 *갱신 모드(0-B)* 를 분기한다.

### Step 1-A: 등록 모드 (`.claude/knowledge/index.md` 가 없을 때)

> **운영 원칙**: 플러그인은 코드·매니페스트에서 용어·요구사항을 *추측하지 않는다.* 모든 항목은 사용자 입력에서 온다.

1. **소비자 확인**: 사용자에게 묻는다 — "이 프로젝트의 knowledge 를 읽을 도구는? (Claude Code 메모리 / Cursor / Codex / Gemini / Copilot / Aider / 사람-온보딩 중 복수)" 이 답변은 §Step 5 에서 *권장 승격 가이드*에 사용.
2. **3종 문서 입력 받기** (모든 항목은 사용자 입력):
   - **용어집**: 핵심 용어 5~15개. 각 용어마다 [한글명, 영문명, 정의(1~3문장), 예시 1개, 관련 PRD/설계 섹션 링크].
   - **기획요구**: 핵심 기획 의도 3~7개. 각 항목마다 [제목, 요약(2~4문장), 출처(`.claude/02-planning/prd.md` 의 어느 섹션)].
   - **기술요구**: 핵심 기술 결정 3~7개. 각 항목마다 [제목, 결정 요약, 출처(`.claude/03-architecture/tech-stack.md`/`system-design.md`/`api-spec.md` 의 어느 섹션)].
3. **요약 확인**: 입력값을 표로 다시 보여주고 *명시적 확인*("위와 같이 등록하시겠습니까?"). 모호·중복 발견 시 `domain-liaison` 에게 통역·중재 위임.
4. **4 파일 동시 작성**:
   - `.claude/knowledge/index.md` — 인덱스 (참조: `references/index-template.md`)
   - `.claude/knowledge/glossary.md` — 용어집 (참조: `references/glossary-template.md`)
   - `.claude/knowledge/product-requirements.md` — 기획요구 (참조: `references/product-requirements-template.md`)
   - `.claude/knowledge/technical-requirements.md` — 기술요구 (참조: `references/technical-requirements-template.md`)
5. **변경 감지 베이스라인 작성**:
   - `.claude/local/knowledge-watch.json` — 4 파일의 경로 + sha256 (콘텐츠 미러 아님, watch 베이스라인일 뿐). 스키마: `references/knowledge-watch-template.json`

### Step 1-B: 갱신 모드 (`.claude/knowledge/index.md` 가 이미 있을 때)

1. **인덱스 우선 표시**: 먼저 `index.md` 만 읽고 사용자에게 보여준다(lazy-load). 3 산출물은 아직 펼치지 않는다.
2. **갱신 대상 확인**: SessionStart 훅(`knowledge-watch.sh`)이 sha256 변경을 보고했으면 강조. 사용자가 *어느 산출물*을 갱신할지 선택할 때까지 그 파일만 펼친다.
3. **항목별 결정**: 사용자에게 *변경/유지/삭제/추가*를 묻는다. 자동 갱신은 하지 않는다. `domain-liaison` 이 기획↔기술 vocabulary 충돌을 통역.
4. **4 파일 갱신**:
   - 변경된 산출물 갱신
   - 인덱스의 해당 섹션 링크/요약 갱신
   - `knowledge-watch.json` 의 sha256 / `updated_at` 갱신

### Step 2: 인덱스의 lazy-load 조각화 점검

인덱스는 *진입점*이지 *전체 사본*이 아니다. 다음을 만족해야 한다:

- 인덱스 한 화면(약 80~120줄) 안에 3 산출물의 *제목/요약/링크*만 들어있다.
- 3 산출물의 본문은 인덱스에 복사되지 않는다.
- 인덱스를 읽는 AI/사람이 "어느 산출물을 더 펼칠지" 판단할 수 있도록 각 산출물의 1~2문장 요약을 둔다.
- 3 산출물은 각자 독립적으로 읽혀도 의미가 통하도록 자족적으로 작성한다.

### Step 3: `domain-liaison` 호출 — 상호 참조 일관성 점검

- 글로서리의 용어가 PRD/기술요구에 어떻게 등장하는지(또는 누락되었는지) 점검.
- 기획↔기술 vocabulary 충돌 식별·합의안 제시.
- 신규 입사자가 인덱스만 읽고도 진입 가능한지 가독성 점검.
- 결과는 `.claude/knowledge/index.md` 의 *상호 참조 노트* 섹션에 1~3 줄로 기록.

### Step 4: SessionStart 훅과의 연계

`knowledge-watch.sh` 는 다음을 수행한다(스킬은 호출하지 않고 훅이 자동 동작):

- `.claude/local/knowledge-watch.json` 이 없으면 한 줄 안내(미등록).
- 있으면 등록된 4 파일의 *현재 sha256*을 베이스라인과 비교.
- 변경된 파일이 있으면 모델 컨텍스트에 *알림*만 주입(자동 갱신 X). 사용자가 `/knowledge` 를 다시 호출해 갱신 모드(Step 1-B)로 진입하도록 안내.

### Step 5: 다중 AI 도구 도달 — 권장 승격 가이드 (자동 X)

> **헌장 D5**: 플러그인은 *어떤 경우에도* `AGENTS.md` 를 자동 생성·수정·승격하지 않는다. 다음은 *권장 안내*만 출력하고, 실행은 사용자가 한다.

사용자에게 다음을 *제안*한다(승격 위치: 루트 `AGENTS.md` 권장):

```
권장 승격 (선택 사항 — 모든 동작은 사용자가 직접):

  옵션 A. 심볼릭 링크 (Unix/Mac, Windows는 git config core.symlinks=true)
    ln -s .claude/knowledge/index.md AGENTS.md
    git add AGENTS.md && git commit -m "chore: link AGENTS.md to knowledge index"

  옵션 B. 직접 이동
    git mv .claude/knowledge/index.md AGENTS.md
    (이후 인덱스 갱신은 루트 AGENTS.md에서 직접 작업)

  옵션 C. 그대로 두기
    `.claude/` 안에 머문다 — Claude Code 만 자동 로드. 다른 AI 도구는 도달 X.
```

도구별 자동 로드 경로 안내(2026-04 기준):

| 도구 | 자동 로드 경로 | 권장 설정 |
|---|---|---|
| Claude Code | 루트 `CLAUDE.md`, `.claude/CLAUDE.md` | `.claude/CLAUDE.md` 안에 `@knowledge/index.md` import |
| Codex CLI | 루트 `AGENTS.md` (또는 fallback) | 옵션 A 심링크 또는 옵션 B 이동 |
| Cursor | `.cursor/rules/*.mdc` | 사용자가 `.mdc` 파일 1개에 `@AGENTS.md` 또는 본문 참조 추가 |
| Gemini CLI | `~/.gemini/GEMINI.md` 등 hierarchical | settings.json `context.fileName` 에 `AGENTS.md` 추가 |
| GitHub Copilot | `.github/copilot-instructions.md` | 본문에 "Project knowledge: see AGENTS.md" 한 줄 |
| Aider | (자동 X) | `.aider.conf.yml` 의 `read: AGENTS.md` |

## 산출물

- **`.claude/knowledge/index.md`** — 인덱스(진입점, lazy-load)
- **`.claude/knowledge/glossary.md`** — 사내 용어집 (평면적: 용어/영문/정의/예시/링크)
- **`.claude/knowledge/product-requirements.md`** — 기획적 요구사항 요약 (PRD 핵심 + 출처 링크)
- **`.claude/knowledge/technical-requirements.md`** — 기술적 요구사항 요약 (tech-stack/설계 핵심 + 출처 링크)
- **`.claude/local/knowledge-watch.json`** — 변경 감지 베이스라인(sha256만, 콘텐츠 미러 아님)

## 트리거 시점

- **수동 트리거** — "용어집 작성", "사내 용어 정리", "온보딩 문서 만들어줘", "knowledge 등록", "AGENTS.md 어떻게 권장?"
- **02-planning, 03-architecture 종료 후 자동 권유** — 신규 PRD/설계 산출물이 생기면 인덱스 갱신을 권유(자동 갱신 아님 — 사용자에게 묻기만).
- **gate-keeper 위임** — Phase 종료 시 "용어 일관성" 검증을 `domain-liaison` 에 위임(`gate-keeper/SKILL.md` 참조).

## 가이드라인

- **lazy-load 강제** — 인덱스 없이 3 산출물을 자동으로 모두 펼치지 않는다.
- **본문은 한 곳에만** — 인덱스에 본문을 복사하지 않는다. 인덱스는 *링크 + 1~2문장 요약*만.
- **사용자 입력 권위** — 코드/매니페스트에서 추측하지 않는다.
- **두 거울 패턴은 도입하지 않는다(v0.6.0)** — `glossary.json` 같은 머신 미러는 *명확한 사용처가 동시 도입될 때* 합의 후 도입.
- **다른 AI 도구 폴더 자동 쓰기 금지** — `.cursor/`, `.codex/` 등에 본 스킬이 직접 쓰는 경로를 만들지 않는다.

## 참고 자료

- **`references/index-template.md`** — 인덱스 템플릿 (lazy-load 헤더·링크·요약)
- **`references/glossary-template.md`** — 용어집 템플릿 (평면 표 형식)
- **`references/product-requirements-template.md`** — 기획요구 템플릿
- **`references/technical-requirements-template.md`** — 기술요구 템플릿
- **`references/knowledge-watch-template.json`** — 변경 감지 베이스라인 스키마

상위 헌장: `docs/direction/2026-04-28-three-doc-set-charter.md`
