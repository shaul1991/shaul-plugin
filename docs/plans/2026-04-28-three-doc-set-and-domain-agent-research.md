# 3종 프로젝트 문서 + 도메인 소통 에이전트 — 조사·설계 초안

- **작성일**: 2026-04-28
- **다음 라운드 입력**: 3종 문서 통합 헌장 + 신규 에이전트 정의(예정)
- **상태**: Draft (사용자 리뷰 대기)
- **관련 계획서**: `~/.claude/plans/jaunty-petting-bird.md` (승인됨)

---

## 1. 조사 배경

### 1-1. 사용자 의도 (시간순 보존)
1. "도메인/비즈니스 용어 등은 어떻게 문서를 관리하고 설정할 수 있는가?"
2. 외부 도구·표준 *조사 먼저*. 글로벌 표준(SKOS, ISO 11179, ContextMapper) 추종 X.
3. 사내에서 쓰는 용어를 정의해 *플러그인 + AI + 신규 입사자* 사이의 싱크가 목적.
4. 용어집은 평면적(용어/정의/영문/예시) 수준. DDD 풀세트 보류.
5. 소비자: 프로젝트 유지보수자(사람) + Claude Code 메모리 + 다른 AI 도구. 단위는 프로젝트 한정.
6. 이번 라운드 범위는 **세 가지 문서 모두** — 사내 용어정리 / 기획적 요구사항 / 기술적 요구사항.
7. **추가**: 위 3종 문서를 매개로 *팀별·도메인 간 소통을 담당하는 전문 에이전트*를 함께 계획.

### 1-2. 현재 플러그인 처리 상태

| 문서 카테고리 | 현재 산출물 | 위치 | 상태 |
|---|---|---|---|
| 사내 용어집 | 없음 | — | **빈틈**. `gate-keeper`가 일관성 *검증*만 함(SKILL.md:77). |
| 기획적 요구사항 | `prd.md`, `user-stories.md`, `scope.md` | `.claude/02-planning/` | 형태 있음. 다중 AI 도구 소비·온보딩 승격 가이드 부재. |
| 기술적 요구사항 | `tech-stack.md` + `stack.json`, `system-design.md`, `data-model.md`, `api-spec.md` | `.claude/03-architecture/` + `.claude/local/` | 형태 있음. tech-stack은 v0.5.0에서 사람/머신 거울 정착. 나머지는 사람 가독만. |
| 도메인 소통 에이전트 | 없음 | — | **빈틈**. 14 에이전트 중 *팀·도메인 사이 통역·중재·용어 일관성*을 일임받은 페르소나 없음. |

### 1-3. 가드레일(불변) — 두 헌장
- **claude-output-charter** (v0.4.0) — `.claude/` 단일 출력, 자동 git tracking 금지, 도구 비종속(원칙 5: 타 AI 도구 폴더에 자동 쓰기 금지). 추적 승격은 사용자 결정.
- **stack-registration-charter** (v0.5.0) — 사용자 입력 권위, 자동 추측 금지, 사람 가독 + 머신 가독 1대1 거울, SessionStart 훅은 알림만.

### 1-4. 조사 도구 한계
이번 세션에 Playwright MCP가 설치되지 않아, 사용자 글로벌 CLAUDE.md 의 폴백 규정("WebSearch는 키워드 검색 시 예외 허용")에 따라 **WebSearch만으로 진행**했다. WebFetch는 사용하지 않았다. 차후 헌장 작성 라운드에서 핵심 인용은 Playwright MCP 로 재검증할 수 있으면 권장.

---

## 2. 영역 A: AI 도구별 컨텍스트 로딩 메커니즘

| 도구 | 자동 로드 경로 | 형식 | import / symlink | 추가 경로 설정 키 | 출처 |
|---|---|---|---|---|---|
| **Claude Code** | 루트 `CLAUDE.md`, `.claude/CLAUDE.md` (양쪽 모두 자동 로드) | Markdown | `@path/to/file` 인라인 import 지원 (상대/절대 경로, 재귀 최대 5 hop). 심링크 transparently follow. | (CLAUDE.md 안 `@`) | code.claude.com/docs/en/memory |
| **Cursor** | `.cursor/rules/*.mdc` (신규), `.cursorrules` (레거시) | Markdown + YAML frontmatter (`description`, `globs`, `alwaysApply`) | (네이티브 import 없음). `globs` 매칭 시 자동 첨부, `alwaysApply: true` 면 항상 첨부 | frontmatter `globs`, `alwaysApply` | docs.cursor.com (community-cited) |
| **Codex CLI (OpenAI)** | 각 디렉터리에서 `AGENTS.override.md` → `AGENTS.md` → `TEAM_GUIDE.md` → `.agents.md` 순으로 첫 매치 1개 채택 | Markdown | (네이티브 `@-import` 없음). 디렉터리 트리에서 root → cwd 순회·연결, 최대 32 KiB | `project_doc_fallback_filenames`, `project_doc_max_bytes` (config) | developers.openai.com/codex/guides/agents-md |
| **Gemini CLI** | 글로벌 `~/.gemini/GEMINI.md` + 프로젝트/조상 + 하위 디렉터리 (계층 결합) | Markdown | (명시적 import 미언급). 계층 자동 결합 | settings.json `context.fileName` (파일명 변경 또는 리스트화) | geminicli.com/docs/cli/gemini-md |
| **GitHub Copilot** | 저장소 전역: `.github/copilot-instructions.md`. 경로별: `.github/instructions/<name>.instructions.md` (`applyTo` frontmatter) | Markdown | (네이티브 import 없음). `applyTo` glob 으로 경로 한정 | 파일 frontmatter `applyTo` | docs.github.com/copilot/customizing-copilot |
| **Aider** | (자동 X) `--read CONVENTIONS.md` 또는 `.aider.conf.yml`의 `read:` 키 | Markdown | (자동 로드 X — 명시 지정 필요). 파일은 read-only 마킹·캐싱 | `.aider.conf.yml`의 `read:` 리스트 | aider.chat/docs/usage/conventions |

**추출 가능한 공통점**:
- 6개 도구 모두 **Markdown 기반**. 기계 가독 JSON·YAML 만의 도구는 없다(프론트매터 보조 정도).
- **자동 로드**가 기본인 도구(Claude/Cursor/Codex/Gemini/Copilot) vs **명시 로드**인 도구(Aider)로 갈린다. 사내 용어집은 *모든 도구가 자동 로드*하는 것이 이상적 → SSOT를 자동 로드 영역에 두어야 한다.
- **import 가 가능한 도구는 Claude Code 만**(`@path`). 나머지는 import 대신 *직접 그 경로의 파일을 읽음*. 따라서 SSOT를 한 곳에 두고 각 도구가 *자기 자동 로드 경로에서 그것을 가리키게* 하는 패턴이 필요하다(symlink 또는 명시적 복사·동기화).

---

## 3. 영역 B: 다중 도구 SSOT 패턴

### 3-1. AGENTS.md — 신규 사실상의 표준
- 2025년 OpenAI·Sourcegraph·Google 협력으로 시작, 2025-12 **Linux Foundation Agentic AI Foundation** 산하 표준화 (Anthropic MCP, Block Goose 와 동급).
- **네이티브 지원**: Codex CLI, GitHub Copilot, Cursor, Windsurf, Amp, Devin.
- **예외**: Claude Code 는 2026-04 시점에도 `AGENTS.md` 를 *네이티브로 자동 로드하지 않는다*. `CLAUDE.md` 가 별도.
- 출처: hivetrail.com 2026 가이드, tessl.io 2026 표준 분석, Linux Foundation 발표.

### 3-2. SSOT 구현 패턴 두 가지
1. **심볼릭 링크**: `ln -s AGENTS.md CLAUDE.md` (또는 반대). git이 심링크를 추적하므로 팀 동기화 자동. Windows 는 `git config core.symlinks=true` 필요. Claude Code 는 심링크를 transparently follow.
2. **`@`-import 활용**: `CLAUDE.md` 본문에 `@AGENTS.md` 한 줄을 두면 Claude Code 가 인라인으로 펼쳐 읽음. 컨텍스트 토큰은 동일하게 소모됨(절약 효과 X — *조직 분리* 효과만).
- 출처: ssw.com.au/rules/symlink-agents-to-claude, kau.sh/blog/agents-md, claudelog.com/faqs/claude-md-agents-md-symlink, coding-with-ai.dev (Unix-style sync).

### 3-3. 우리에게 시사점
- **3종 문서를 한 인덱스(예: `AGENTS.md`)로 묶고, 그 인덱스가 3종 산출물을 명시 참조**(혹은 `@`-import)하면 다음을 동시에 만족:
  - Codex/Cursor/Copilot/Gemini 등이 `AGENTS.md`(혹은 자기 경로의 사본·심링크)를 자동 로드 → 3종 문서 도달.
  - Claude Code 는 `.claude/CLAUDE.md` 안에서 같은 3종을 `@`-import 또는 인덱스 경로 참조 → 도달.
  - 사람(온보딩)은 인덱스 한 페이지에서 3종 진입점을 본다.
- **단, 헌장 원칙 5 — "타 AI 도구 폴더에 자동 쓰기 금지"** — 위반 우려: 플러그인이 `AGENTS.md` 를 *자동 생성·갱신*하면 그 자체가 다른 AI 도구의 영역에 쓰는 것으로 해석될 여지. 안전 경로: 플러그인은 `.claude/` 안에서 3종 문서를 작성하고, *사용자가 이동·심링크·복사*하는 시점에만 외부 영역에 닿게 한다.

---

## 4. 영역 C: 실무 3종 세트 샘플 (참고용)

### 4-1. CNCF Cloud Native Glossary
- 저장소: github.com/cncf/glossary
- 한 용어 = 한 마크다운 파일(예: `content/en/kubernetes.md`).
- 문구 톤: 비기술자도 이해 가능한 평이한 정의 + 짧은 예시.
- 다국어: 폴더 분리(`content/en/`, `content/ko/` 등).
- 갱신: 커뮤니티 PR.

### 4-2. Kubernetes 공식 Glossary
- 사이트: kubernetes.io/docs/reference/glossary/
- 단일 페이지에 알파벳 색인 + 카드 형식 정의.
- 정의는 1~3 문장 짧음. 깊은 설명은 별도 문서로 링크.
- 분량 감각: 약 90 용어, 페이지 길이 ~한 화면 스크롤(인덱스).

### 4-3. 우리에게 시사점
- **평면적 용어집**(사용자 명시 범위)과 정합. 한 파일 vs 디렉터리·파일 분리는 양쪽 다 산업에 존재. 우리 규모(프로젝트 단위, 평면)는 **단일 파일** 이 적합.
- 정의는 짧게(1~3 문장), 깊은 설명은 PRD/설계로 링크 — 3종 문서 *상호 참조 일관성*을 신규 에이전트가 책임진다(영역 D 참조).

---

## 5. 도출한 통합 패턴 후보 (3종 문서 동시 적용 가능)

세 옵션 모두 *3종 문서에 동시 적용 가능*하다는 것을 전제로 작성. 각 옵션은 두 헌장과의 정합성을 표기.

### 옵션 1 — 인덱스 + 3산출물 (AGENTS.md 표준 흡수)
- `.claude/knowledge/index.md` (또는 사용자 승격 후 `AGENTS.md` 후보) — 3종 문서 진입점.
- `.claude/knowledge/glossary.md` — 사내 용어집(신규).
- 기획요구는 기존 `.claude/02-planning/` 그대로, 인덱스가 *링크*만 함.
- 기술요구는 기존 `.claude/03-architecture/` 그대로, 인덱스가 *링크*만 함.
- 사용자가 인덱스를 `AGENTS.md`(또는 `docs/AGENTS.md`)로 *이동/심링크* 하면 타 AI 도구가 자동 로드. Claude Code 는 `.claude/CLAUDE.md` 에서 인덱스를 `@`-import.

| 평가 항목 | 결과 |
|---|---|
| claude-output-charter 정합 | ✅ 모든 산출물 `.claude/` 안에서 시작. 외부 영역 자동 쓰기 없음. |
| stack-registration-charter 정합 | ✅ 사용자 입력 권위·SessionStart 알림만 패턴 그대로 적용 가능. |
| 다중 AI 도구 도달 | ✅ 사용자가 인덱스 1회 승격 시 모든 도구가 도달. |
| 온보딩 가독성 | ✅ 인덱스 한 페이지가 3종 진입점. |
| 유지보수 비용 | 중 — 인덱스 갱신 책임 발생. 신규 에이전트(영역 D)가 일임. |

### 옵션 2 — 평면 3파일, 인덱스 없음
- `.claude/knowledge/glossary.md`, `.claude/knowledge/product-requirements.md`, `.claude/knowledge/technical-requirements.md` 세 파일 동등.
- 사용자가 도구별 자동 로드 경로에서 각 3 파일을 *각자* 가리키게 1회 설정.

| 평가 항목 | 결과 |
|---|---|
| 헌장 정합 | ✅ 동일. |
| 다중 AI 도구 도달 | △ 3 경로 × 도구 수 만큼 사용자 설정 부담. |
| 온보딩 가독성 | △ 진입점이 3개. 신규 입사자가 무엇부터 읽을지 불명확. |
| 유지보수 비용 | 낮음 — 인덱스 갱신 부담 없음. |

### 옵션 3 — 사람 가독 + 머신 미러 거울 (tech-stack 패턴 풀 계승)
- 옵션 1 위에 추가로: `.claude/local/glossary.json`, `.claude/local/product-requirements.json`, `.claude/local/technical-requirements.json` 머신 미러.
- SessionStart 훅이 머신 미러를 읽어 컨텍스트 주입(`stack-watch.sh` 패턴).

| 평가 항목 | 결과 |
|---|---|
| 헌장 정합 | ✅ 모두 정합. stack-charter 패턴 풀 계승. |
| 다중 AI 도구 도달 | ✅ 옵션 1과 동일(머신 미러는 도구 비공개). |
| 온보딩 가독성 | ✅ 사람은 .md만 읽음. |
| 유지보수 비용 | 높음 — 두 파일 동기화 책임. tech-stack은 단일 산출물이라 부담 작았으나 3배가 되면 무거워질 수 있음. |
| 머신 가독 활용성 | 명확한 사용처가 있을 때만 가치(예: `sync-check`가 코드와 매칭, SessionStart가 변경 알림). 명확한 사용처가 부재하면 *과대 설계*. |

### 추천 (잠정)
**옵션 1**이 비용 대비 효용 최대. 옵션 3 의 머신 미러는 *사용처가 명확해진 시점*(예: `sync-check`이 글로서리 ↔ 코드 매칭 기능을 추가할 때)에 부분 도입. 사용자 결정은 §8 Q1·Q4.

---

## 6. 영역 D: 신규 도메인 소통 에이전트 드래프트

### 6-1. 작명 후보 + 추천
| 후보 | 한국어 | 톤 | 기존 패턴 매칭 |
|---|---|---|---|
| `domain-liaison` ★ | 도메인 연락관 | 직설적·중립 | 직접적 표현 |
| `glossary-steward` | 용어집 청지기 | 소유 책임 강조 | 신규 (steward 미사용) |
| `cross-team-coordinator` | 팀간 코디네이터 | 활동 범위 강조 | `setup-coordinator`와 동형 |
| `domain-translator` | 도메인 번역가 | 비공식·기능 중심 | 신규 (translator 미사용) |

**추천**: `domain-liaison` — 사용자 요구 표현("도메인 등 사이간의 소통을 담당하는 전문 agent")과 가장 직접 매핑. 단, 사용자가 `setup-coordinator` 패턴 일관성을 우선시하면 `cross-team-coordinator` 로 변경 가능. (§8 Q6)

### 6-2. 페르소나 (한 줄)
> "팀과 도메인 사이를 잇는 시니어 도메인 연락관. 3종 문서(용어집·기획요구·기술요구)의 상호 참조 일관성을 책임지고, 기획↔기술 vocabulary 충돌 시 통역·중재하며, 신규 입사자에게는 온보딩 가이드의 청지기."

### 6-3. 핵심 책임 (4)
1. 3종 문서의 *작성·갱신을 보조*하고 *상호 참조 일관성*을 유지(용어집의 항목이 PRD·설계에 어떻게 등장하는지 점검).
2. 기획 vs 기술 vocabulary 충돌 시 *통역·중재* — 같은 개념의 서로 다른 표현을 식별하고 합의안 제시.
3. 신규 입사자 질문에 *3종 문서 기반*으로 답변. 부족한 정의는 사용자에게 입력 요청 후 글로서리에 추가.
4. 다른 AI 도구(`AGENTS.md` 표준 도구들)가 SSOT 인덱스를 가리키도록 사용자에게 *수동 설정 가이드* 제공. 자동 쓰기 금지(헌장 원칙 5 준수).

### 6-4. 트리거 키워드 (한/영)
- 한: "용어집 작성", "용어 정의해줘", "팀 간 용어 충돌", "온보딩 문서 만들어줘", "신규 입사자 가이드", "이 용어 뭔지 알려줘", "도메인 정리".
- 영: "glossary", "ubiquitous language" (DDD 풀세트 X 임을 명시), "domain term", "onboarding doc".

### 6-5. 도구 권한
**최소 권한**:
- `Read`, `Write`, `Edit`, `Glob`, `Grep` — 기존 phase 에이전트 표준 세트(10/14 에이전트와 동일).
- `Bash` 미부여 — 본 에이전트는 코드 실행이 아닌 문서 작업.
- `WebFetch`, `WebSearch` 미부여 — 외부 조회는 사용자가 별도 도구로(헌장 원칙 일관성).

### 6-6. 호출 시점
- 신규 `glossary` 스킬(예정)에서 자동 위임.
- `02-planning` SKILL이 PRD/유저스토리 작성 후 *용어 일관성 점검* 콜로 호출.
- `03-architecture` SKILL이 데이터 모델·API 명세 작성 후 *용어 일관성 점검* 콜로 호출.
- `gate-keeper` 의 "용어 일관성" 행 위임 여부는 §8 Q7.

### 6-7. 기존 에이전트와의 역할 분담
| 기존 에이전트 | 역할 분담 |
|---|---|
| `project-manager` | 일정·우선순위. 본 에이전트와 비충돌. |
| `alm-manager` | 추적성·릴리즈·기술부채. 비충돌(추적성 *연결*은 alm-manager, 용어 *일관성*은 본 에이전트). |
| `quality-reviewer` | 산출물 *완결성·정합성* 게이트. 본 에이전트는 *콘텐츠*(용어), quality-reviewer 는 *형식·완결성*. |
| `code-analyst` | 코드 분석. 글로서리↔코드 드리프트 탐지에서 협업. |
| `product-planner`, `system-architect` | 각각 PRD·설계의 1차 저자. 본 에이전트는 그 위에서 vocabulary 일관성을 점검. |

### 6-8. 비범위 (non-goals)
- 코드 직접 수정 — `lead-developer` 영역.
- 비즈니스 의사결정 — `product-planner` 영역.
- 일정·예산 추정 — `project-manager`, `alm-manager` 영역.
- 다른 AI 도구의 *컨텍스트 파일을 자동 작성·수정* — 헌장 원칙 5 위반.

### 6-9. 산출물 위치 (헌장 정합)
- 본 에이전트가 만드는 모든 파일은 `.claude/` 안에서 시작.
- 인덱스(옵션 1 채택 시): `.claude/knowledge/index.md` (사용자가 `AGENTS.md` 등으로 승격 시점에만 외부 영역 진입).
- 글로서리: `.claude/knowledge/glossary.md`.
- 다른 AI 도구의 컨텍스트 파일 자동 생성·수정 절대 X.

### 6-10. 제안 frontmatter 스켈레톤 (다음 라운드 입력)
```yaml
---
name: domain-liaison
description: >
  팀별·도메인 사이의 소통을 담당하는 도메인 연락관. 사내 용어집·기획요구·기술요구
  3종 문서의 상호 참조 일관성을 유지하고, 기획-기술 vocabulary 충돌을 통역·중재하며,
  신규 입사자 온보딩 가이드의 청지기 역할.
  
  사용 예:
  - "이 용어 정의해줘" / "팀 간 용어 충돌"
  - "신규 입사자가 읽을 가이드 만들어줘"
  - "PRD 와 설계 문서의 용어가 일치하는지 점검"
model: inherit
color: purple
tools: ["Read", "Write", "Edit", "Glob", "Grep"]
---
```

(섹션 본문 헤더는 기존 14 에이전트 패턴 — 페르소나 / 핵심 역량 / 작업 원칙 / 작업 절차 / 산출물 / 커뮤니케이션 스타일 — 을 따른다.)

---

## 7. 두 헌장과의 정합성 검토

### 7-1. claude-output-charter (v0.4.0)
| 원칙 | §5 옵션 1·2·3 | §6 신규 에이전트 |
|---|---|---|
| 1. 루트는 코드만, 자동 외부 쓰기 X | ✅ 모두 `.claude/`에서 시작. 외부 진입은 사용자 결정. | ✅ 산출물 모두 `.claude/`. |
| 2. 모든 산출물 `.claude/` 하위 단계별 폴더 | ✅ 옵션 모두 `.claude/knowledge/` 신설로 정합. | ✅ 정합. |
| 3. `.claude/` 전체 ignore | ✅ 변동 없음. | ✅ 변동 없음. |
| 4. 추적은 사용자 결정 | ✅ 승격 동작은 사용자 수동. | ✅ 인덱스 승격도 수동. |
| 5. 도구 비종속 — 타 AI 폴더 자동 쓰기 X | ✅ AGENTS.md 자동 *생성*도 우리 영역 안에서만. 외부 위치로의 이동·심링크는 사용자 동작. | ✅ 비범위에 명시. |

**위반 후보 0건**.

### 7-2. stack-registration-charter (v0.5.0)
| 원칙 | §5·§6 적용 |
|---|---|
| 1. 추측 X, 사용자 입력 권위 | ✅ 글로서리 항목·기획·기술 정의 모두 사용자 입력에서 옴. 자동 추출(예: 코드에서 식별자 채굴해 글로서리 자동 등록) 금지. |
| 2. 사람 가독 + 머신 가독 1대1 거울 | △ 옵션 3 만 풀 계승. 옵션 1·2 는 사람 가독만. 사용자 결정(§8 Q4)에 따라 유지/거부. |
| 3. 다중 프로젝트 1급 시민 | △ 모노레포면 글로서리도 프로젝트별 분할 필요. §8 에 추가 질문 필요(아래 Q2 의 변형). |
| 4. 변경 감지는 알림만, 결정은 사용자 | ✅ 신규 에이전트의 드리프트 탐지도 *알리기*만. |
| 5. watched 범위 작은 화이트리스트 | △ 글로서리 자동 변경 감지의 watched 범위는 §8 Q5 에서 결정. |

---

## 8. 사용자 결정이 필요한 열린 질문 (7)

다음 라운드(헌장 작성)로 가기 전에 사용자 답변이 필요한 항목:

1. **Q1 — 인덱스 vs 평면**: §5 옵션 1(인덱스 + 3산출물)을 채택할 것인가, 옵션 2(평면 3파일)으로 갈 것인가? 추천은 옵션 1.
2. **Q2 — 산출물 시작 위치**: 신규 통합 위치 `.claude/knowledge/` 신설하고 3 산출물을 모두 거기 둘 것인가, 아니면 글로서리만 신규 위치에 두고 기획요구는 `.claude/02-planning/`, 기술요구는 `.claude/03-architecture/` 그대로 둘 것인가? (모노레포 분할 정책도 함께 결정 — stack-charter 원칙 3 정합)
3. **Q3 — 권장 승격 위치**: 사용자에게 `AGENTS.md`(루트), `docs/AGENTS.md`, `docs/glossary.md` + 분리 등 어떤 패턴을 *권장*할 것인가? 권장만 하고 실제 이동은 사용자 결정.
4. **Q4 — 머신 미러 채택 여부**: 옵션 3(JSON 미러)을 부분/전부 채택할 것인가, 사람 가독만으로 끝낼 것인가? 미러를 둔다면 명확한 사용처(예: `sync-check`)가 함께 필요.
5. **Q5 — SessionStart 훅 동작**: 3종 문서에 대해 무엇을 알릴 것인가? 후보: (a) 부재 알림(글로서리 미작성 안내), (b) 코드 내 식별자가 글로서리에 없을 때 알림, (c) 매니페스트 변경처럼 특정 트리거 변경 시 갱신 검토 권고, (d) 아무것도 안 함.
6. **Q6 — 신규 에이전트 작명**: `domain-liaison` / `glossary-steward` / `cross-team-coordinator` / `domain-translator` 중 어느 쪽? 추천 `domain-liaison`.
7. **Q7 — gate-keeper "용어 일관성" 행 위임**: 신규 에이전트가 위임받아야 하는가, `gate-keeper`가 자체 검증을 유지하고 신규 에이전트는 별도 협업으로 둘 것인가?

---

## 9. 참고 출처

(WebSearch 결과 페이지 URL. Playwright MCP 미설치로 직접 페이지 fetch 는 미수행. 차후 헌장 라운드에서 핵심 항목은 Playwright 로 재검증 권장.)

1. Claude Code 메모리 — https://code.claude.com/docs/en/memory
2. Cursor `.cursor/rules` 동작 — https://docs.cursor.com/en/context/rules (커뮤니티 인용)
3. Codex CLI AGENTS.md — https://developers.openai.com/codex/guides/agents-md
4. Gemini CLI GEMINI.md — https://geminicli.com/docs/cli/gemini-md/
5. GitHub Copilot custom instructions — https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot
6. Aider conventions — https://aider.chat/docs/usage/conventions.html
7. Aider config — https://aider.chat/docs/config/aider_conf.html
8. AGENTS.md 표준화 동향(LF Agentic AI Foundation) — https://hivetrail.com/blog/agents-md-vs-claude-md-cross-tool-standard, https://tessl.io/blog/the-rise-of-agents-md-an-open-standard-and-single-source-of-truth-for-ai-coding-agents/
9. AGENTS.md ↔ CLAUDE.md 심링크 패턴 — https://www.ssw.com.au/rules/symlink-agents-to-claude, https://kau.sh/blog/agents-md/
10. CNCF Cloud Native Glossary 사례 — https://github.com/cncf/glossary, https://kubernetes.io/docs/reference/glossary/

---

## 10. 다음 라운드(헌장 작성) 입력 요약

사용자가 §8 Q1~Q7 에 답변하면, 다음 라운드에서 다음 산출물을 만든다(이번 라운드 비범위):

- `docs/direction/2026-04-28-three-doc-set-charter.md` (또는 적절한 슬러그) — 3종 문서 통합 헌장.
- `claude-code-plugin/project-lifecycle/skills/glossary/SKILL.md` — 신규 크로스커팅 스킬.
- `claude-code-plugin/project-lifecycle/agents/<선정명>.md` — 신규 에이전트 정의(이 노트 §6 의 드래프트를 본문화).
- 기존 SKILL 본문 패치(`02-planning`, `03-architecture`, `gate-keeper`, `00-setup` 의 인덱스/연계 부분).
- `CHANGELOG.md` 항목 + 마켓플레이스 매니페스트 버전 갱신.
- (선택) SessionStart 훅 확장(`knowledge-watch.sh` 등) — Q5 결정에 따라.
