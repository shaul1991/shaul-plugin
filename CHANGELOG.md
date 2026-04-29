# Changelog

All notable changes to the **project-lifecycle** Claude Code plugin are tracked
here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] — 2026-04-29

### Added — Review Backend Branching
- **신규 스킬 `codex-reviewer`** (`skills/codex-reviewer/SKILL.md`).
  외부 OpenAI Codex CLI 를 Bash 로 호출해 Phase 산출물을 평가하는 백엔드 스킬.
  사용자 키워드 트리거 없음 — `07-qa` Step 0 디스패처가 `reviewer: "codex"` 또는
  `"cross"` 일 때만 호출. 평가 프레임워크는 `quality-reviewer` 에이전트와 동일하게
  사용해 두 백엔드의 판정이 비교 가능하도록 보존.
  - 프롬프트는 *반드시 파일* (`.claude/local/codex/<phase>-<ts>.prompt.md`)로 전달 →
    인라인 heredoc 경로의 secret-guard 토큰 차단 회피.
  - 결과 파일 `.claude/reviews/<phase>-codex-<ts>.md` 헤더 5줄(backend/model/exit/ts/hash)
    로 감사 재현성 확보.
  - 명령어 라인은 한 줄에 모아 두고 TBD 라벨 — 설치된 `codex --help` 확인 후 정확한
    verb/flag 로 교체 (스킬 안 한 곳만 고치면 됨).
- **참고 자료 `skills/codex-reviewer/references/codex-prompt-template.md`** — codex 에
  전달하는 평가 프롬프트 형식. Phase 별 체크리스트, cross-review 정합성 표,
  `Verdict: Go|Iterate|No-Go` 출력 schema 강제.
- **시작 샘플 `hooks/review-config-template.json`** — `.claude/review-config.json` 으로
  복사해 편집할 수 있는 템플릿. 스키마 v1: `reviewer`(claude/codex/cross), `codex`
  블록(model·timeout·extra_flags), `per_phase_overrides`, `_writer_reserved`(미래 PR 슬롯).
- **`00-setup` SKILL Step 8 신설 — 리뷰 백엔드 정책 리뷰**. Phase 0 에서 사용자에게
  (1) 백엔드 선택지(`claude`/`codex`/`cross`), (2) `command -v codex` 로 실제 설치 여부 탐지,
  (3) 정책 파일 작성/보류 분기, (4) 우회 메커니즘(`CLAUDE_PLUGIN_REVIEWER` 환경변수) 을
  명시적으로 안내. 사용자가 보류하면 정책 파일 미작성 — 내장 기본값 `claude` 적용.

### Changed
- **`07-qa` SKILL Step 0 신설 — 리뷰 백엔드 결정**. Phase 7 의 모든 평가 흐름 앞단에
  디스패처를 배치. 해석 우선순위: `CLAUDE_PLUGIN_REVIEWER` 환경변수 → `.claude/review-config.json`
  (`per_phase_overrides["07"]` 우선, 없으면 `reviewer`) → 내장 기본 `claude`. 결정된
  백엔드를 사용자에게 한국어로 *반드시* announce. Phase 7 산출물 계약(`.claude/07-qa/`)
  은 변경 없음 — 평가 결과 파일명만 백엔드별로 구분.
- Cross 모드 정책 — 두 백엔드 결과를 나란히 보여주고 *사람이 최종 판정*. 자동 차단
  없음(사용자 결정). 비교 파일 `.claude/reviews/<phase>-cross-<ts>.md` 에 항목별 일치/
  불일치 표 + "사람의 최종 판정" 섹션.

### Compatibility
- **기본 동작 변경 없음** — 정책 파일·환경변수 모두 없으면 v0.7.0 과 동일하게
  `quality-reviewer` 에이전트가 단독 실행.
- **`agents/quality-reviewer.md` 변경 없음** — 디스패처는 스킬 레이어에 격리.
- **`writer` 분기는 schema 만 예약**(`_writer_reserved`). `05-implementation` 스킬은
  미수정. 다음 PR 에서 `writer: "codex"` 추가 시 기존 설정에 영향 없음.

### Migration (v0.7.x → v0.8.0)
별도 작업 불필요. 머지 후 다음 세션부터 `07-qa` 에 Step 0 이 자동 발효된다.
- 정책 미설정: `quality-reviewer` 가 그대로 동작 (v0.7.0 과 동일).
- 백엔드 변경: `cp claude-code-plugin/project-lifecycle/hooks/review-config-template.json .claude/review-config.json` 후 `reviewer` 값을 `codex` 또는 `cross` 로 편집.
- 일시 변경: `CLAUDE_PLUGIN_REVIEWER=codex claude` 로 세션 시작.
- Codex 사전 조건: `codex` CLI 설치 + `codex login`. 미설치/미인증 시 `claude` 로 자동 폴백
  또는 명시적 중단(인증 누락은 사용자 액션 필요).

## [0.7.0] — 2026-04-28

### Added — Security
- **`PreToolUse` 시크릿 파일 가드 훅** (`hooks/secret-guard.sh`).
  `Read`/`Edit`/`Write`/`Bash` 도구가 시크릿 파일을 만지려 시도하면 *차단*하거나
  *사용자에게 묻기*. 플러그인의 어느 step·skill·에이전트에서도 *무조건* 적용된다.
  - 차단(`always_block`) → `permissionDecision: "deny"` + exit 2
  - 묻기(`ask_before_read`) → `permissionDecision: "ask"` (Claude Code 인라인 프롬프트)
  - 통과 → 무출력 + exit 0
- **사용자 정책 파일 `.claude/secret-guard.json`**. 사용자가 직접 편집 가능한 JSON.
  스키마 v1: `always_block`(deny), `ask_before_read`(ask), `exempt_suffixes`(템플릿 예외).
  매칭은 *basename* 기준 fnmatch 글롭(`*`, `?`, `[..]`). 정책 파일 부재 시 내장 기본값
  적용(`.env`, `.env.*` 차단 + `.example`/`.sample`/`.template`/`.dist` 예외).
- **시작 샘플 `hooks/secret-guard-template.json`** — `.claude/secret-guard.json` 으로 복사해
  편집할 수 있는 템플릿. 흔한 후보(예: `id_rsa*`, `*.pem`, `.aws/credentials`) 는 `$examples`
  로 안내.
- **Opt-out**: `CLAUDE_PLUGIN_SECRET_GUARD=off` (또는 `0`/`false`) 한 가지. 세션 단위·명시적.
  우회 시 stderr 알림.
- `docs/direction/2026-04-28-secret-file-guardrail-charter.md` — 본 보안 정책의 사용자 원문
  요구·도출 원칙·설계 결정·미래 변경 가드레일을 보존하는 헌장.

### Changed
- `hooks/hooks.json` 에 `PreToolUse` 항목 신설 (matcher: `Read|Edit|Write|Bash`). 기존
  `SessionStart` 3 훅(`bootstrap-local.sh`, `stack-watch.sh`, `knowledge-watch.sh`) 은 그대로.
- 본 가드는 `permissions.deny` settings.json 을 ship 하지 *않는다*. 사용자
  `settings.local.json` 우선순위가 plugin settings 보다 높아 *무조건 적용* 보장이
  깨지기 때문(헌장 D12). 훅으로 일원화.
- **`00-setup` SKILL Step 7 신설 — 시크릿 파일 가드 정책 리뷰**. Phase 0 종료
  전에 사용자에게 (1) 가드 활성 사실, (2) 정책 커스터마이즈 의향, (3) 일시 해제
  메커니즘(`CLAUDE_PLUGIN_SECRET_GUARD=off`) 을 *명시적으로 한 번* 안내한다.
  사용자가 추가 항목 제시 시에만 `.claude/secret-guard.json` 을 작성(추측·자동
  채굴 X). 가드 자체는 플러그인 설치만으로 이미 동작 중이지만, *사용자가 인지하는
  보안* 만이 실제 보안이라는 원칙에 따라 초기 셋업 단계에 보안 의식 형성을
  자연스럽게 통합.
- `setup-coordinator` 에이전트 — 행동 원칙 5(보안 의식 형성은 *지금*) 및
  전문 영역에 시크릿 파일 가드 정책 리뷰 추가. "사용자가 명시하지 않은 파일은
  추가하지 않는다" 가드레일 명시.

### Migration (v0.6.x → v0.7.0)
별도 작업 불필요. 머지 후 다음 세션부터 `PreToolUse` 가 자동 발효된다.
- 기본 동작: `.env`, `.env.*` 접근 차단(`.env.example` 등 템플릿 예외).
- 정책 커스터마이즈: `cp claude-code-plugin/project-lifecycle/hooks/secret-guard-template.json .claude/secret-guard.json` 로 시작 샘플을 복사한 뒤 편집. 다음 도구 호출부터 즉시 반영.
- 일시 해제: `CLAUDE_PLUGIN_SECRET_GUARD=off claude` (세션 종료 시 자동 복원).

## [0.6.0] — 2026-04-28

### Added
- **사내 3종 문서 통합 관리 (`knowledge` 스킬).** 신규 크로스커팅 스킬이
  `.claude/knowledge/` 영역에 4 산출물을 사용자 입력 기반으로 등록·갱신한다:
  - `index.md` — 진입점 인덱스(lazy-load: 항상 인덱스부터, 3 산출물은 필요할 때만 펼침)
  - `glossary.md` — 사내 평면 용어집(용어/영문/정의/예시/링크)
  - `product-requirements.md` — 기획적 요구사항 요약(PRD 핵심 + 출처 링크)
  - `technical-requirements.md` — 기술적 요구사항 요약(설계 핵심 + 출처 링크)
  플러그인은 코드/매니페스트에서 추측하지 않으며, 모든 항목은 사용자 입력에서 온다.
- **신규 전문 에이전트 `domain-liaison` (도메인 연락관).** 14 → 15 에이전트.
  팀별·도메인 간 소통, 3종 문서 상호 참조 일관성, 기획↔기술 vocabulary
  통역·중재, 신규 입사자 온보딩 가이드 청지기 역할. `gate-keeper` 의
  "용어 일관성" 검증을 위임받는다.
- **SessionStart knowledge 변경 감지** (`hooks/knowledge-watch.sh`). 4 파일의
  sha256 을 등록 시점 베이스라인(`.claude/local/knowledge-watch.json`)과
  비교해 변경 시 모델 컨텍스트에 *알림*만 주입(자동 갱신 X). 베이스라인은
  *콘텐츠 미러가 아니라* 경로 + sha256 만 담는 변경 감지 메타데이터다.
- **루트 `AGENTS.md` 권장 가이드.** 다중 AI 도구(Codex CLI, Cursor, Copilot,
  Gemini, Aider 등) 도달을 위해 사용자가 인덱스를 루트 `AGENTS.md` 로
  *수동 이동·심링크* 하는 것을 권장. 플러그인은 *어떤 경우에도 `AGENTS.md` 를
  자동 생성·수정·승격하지 않는다* (헌장 원칙 5 — 도구 비종속).
- `references/index-template.md`, `references/glossary-template.md`,
  `references/product-requirements-template.md`,
  `references/technical-requirements-template.md`,
  `references/knowledge-watch-template.json` — knowledge 스킬 템플릿 5종.
- `docs/direction/2026-04-28-three-doc-set-charter.md` — 본 변경의 사용자
  원문 요구·도출 원칙·설계 결정을 보존하는 헌장.
- `docs/plans/2026-04-28-three-doc-set-and-domain-agent-research.md` —
  헌장 입력이 된 외부 AI 도구 조사 노트.

### Changed
- `gate-keeper/SKILL.md` Step 4 의 "용어 일관성" 행이 `domain-liaison` 에
  검증 위임 형태로 바뀌었다. 게이트 표는 그대로 유지되며, 글로서리 미등록
  프로젝트에서는 *⚠️ N/A — knowledge 미등록* 으로 표기 후 `/knowledge`
  호출을 권유한다(자동 등록 X).
- `00-setup/SKILL.md` Step 6 신설 — knowledge 영역 *권유* 안내. 자동
  생성하지 않는다.
- SessionStart 훅이 세 단계로 동작: ① `bootstrap-local.sh` ②
  `stack-watch.sh` ③ `knowledge-watch.sh` (신규).

### Migration (v0.5.x → v0.6.0)
별도 작업 불필요. 기존 사용자가 `/knowledge` 를 호출하면 SKILL 이
*등록 모드* 로 진입해 3종 문서 입력을 받는다. 4 파일 작성과
`.claude/local/knowledge-watch.json` 베이스라인이 같이 만들어지고,
이후 세션부터 SessionStart 훅(`knowledge-watch.sh`)이 변경 감지를 시작한다.
다른 AI 도구 도달이 필요하면 사용자가 직접 `ln -s .claude/knowledge/index.md AGENTS.md`
또는 `git mv .claude/knowledge/index.md AGENTS.md` 등 *수동 승격*을 수행한다.

## [0.5.0] — 2026-04-28

### Added
- **사용자 입력 기반 기술 스택 등록·갱신.** 03-architecture 스킬이
  단일/다중 프로젝트(모노레포) 모두에 대해 *사용자가 직접 입력한*
  언어·프레임워크를 두 산출물에 동시에 기록한다 — 사람 가독 ADR
  `.claude/03-architecture/tech-stack.md` 와 머신 가독 미러
  `.claude/local/stack.json`. 플러그인은 자동으로 추측하지 않으며,
  모든 정보는 사용자 입력에서 온다.
- **SessionStart 매니페스트 변경 감지** (`hooks/stack-watch.sh`).
  세션 시작 시 등록된 각 프로젝트의 watched 매니페스트의 sha256 을
  현재 파일과 비교해, 등록 시점과 달라졌으면 모델 컨텍스트에
  변경 알림과 함께 *03-architecture 갱신 검토 권장* 메시지를 주입한다.
  자동 갱신은 하지 않는다 — 변경의 적용은 사용자가 03-architecture 를
  다시 호출했을 때만 일어난다 (헌장: 추적은 사용자 결정).
- 1차 watched 매니페스트 범위: PHP+Laravel 의 `composer.json`,
  Python+FastAPI 의 `pyproject.toml` / `requirements.txt`. 사용자는
  ADR 에 어떤 언어/프레임워크든 자유롭게 등록할 수 있으며, 1차 범위 외는
  `watched_manifests: []` 로 두어 사용자가 직접 갱신 호출.
- `references/stack-json-template.json` — `stack.json` 스키마 v1 예시
  (다중 프로젝트 포함).
- `docs/direction/2026-04-28-stack-registration-charter.md` — 본 변경의
  사용자 원문 요구·도출 원칙·설계 결정을 보존하는 헌장.

### Changed
- `03-architecture/SKILL.md` 의 Step 1 이 *기술 스택 선정* →
  *기술 스택 등록 또는 갱신(사용자 입력 우선)* 로 확장. 워크스페이스
  구조(단일/다중 프로젝트) 입력, 두 파일 동시 작성, 갱신 모드의
  변경 항목 강조 절차를 명시.
- SessionStart 훅이 두 단계로 동작: ① `bootstrap-local.sh` (기존,
  `.claude/local/plans/` + `.gitignore` 라인 보장) ② `stack-watch.sh`
  (신규, stack.json 미등록 시 안내 / 등록 시 변경 감지).

### Migration (v0.4.x → v0.5.0)
별도 작업 불필요. 기존 사용자가 `/03-architecture` 를 호출하면 SKILL 이
*등록 모드*로 진입해 워크스페이스 구조와 각 프로젝트의 언어·프레임워크를
물어본다. 응답에 따라 `tech-stack.md` 와 `.claude/local/stack.json` 이
같이 작성되고, 이후 세션부터는 SessionStart 훅이 변경 감지를 시작한다.
이미 `tech-stack.md` 가 있다면 SKILL 이 그 내용을 stack.json 에 옮겨
적도록 안내한다.

## [0.4.0] — 2026-04-28

### Changed (BREAKING — output layout)
- 모든 플러그인 산출물이 `.claude/` 하위로 이동했다. 이전 위치 → 새 위치:
  - `docs/<NN-phase>/...` → `.claude/<NN-phase>/...`
  - `docs/lifecycle.md` → `.claude/lifecycle.md`
  - `docs/tech-debt-registry.md` → `.claude/tech-debt-registry.md`
  - `docs/kpi-definitions.md` → `.claude/kpi-definitions.md`
  - 루트 `CLAUDE.md` → `.claude/CLAUDE.md` (Claude Code가 양쪽 모두 자동 로드)
- `.gitignore` 등록 라인이 `.claude/local/` → `.claude/`로 확대되었다.
  플러그인이 만드는 모든 산출물(단계 폴더, 실행계획서, ALM 추적 파일,
  에이전트 컨텍스트)이 일괄적으로 git 추적에서 제외된다.
- SessionStart 훅이 기존 프로젝트의 `.gitignore`에서 레거시 `.claude/local/`
  라인을 자동으로 `.claude/`로 교체한다 (멱등, 한 번만, 무중단 업그레이드).
- 산출물 공유 방식이 **사용자 결정 추적**으로 명확해졌다. 팀과 공유할
  산출물은 사용자가 `git mv .claude/02-planning/prd.md docs/...`처럼 `.claude/`
  밖으로 직접 이동시킨다. `git add -f`나 un-ignore 라인 같은 우회는 권장하지 않는다.

### Removed
- `00-setup` 스킬에서 `.editorconfig` 자동 생성을 제거했다. 에디터 설정은
  프로젝트 루트에 있어야 의미가 있어 "루트는 프로젝트 코드만"이라는
  v0.4.0 원칙과 충돌한다. 샘플 스니펫은
  `skills/00-setup/references/team-conventions-template.md`로 옮겨, 필요하면
  사용자가 직접 루트에 생성한다.

### Migration (v0.3.x → v0.4.0)
1. `.claude/` 폴더 준비: `mkdir -p .claude`
2. `docs/<NN-phase>/`를 `.claude/<NN-phase>/`로 이동:
   ```bash
   for d in 00-setup 01-ideation 02-planning 03-architecture 04-design \
            05-implementation 06-infra 07-qa 08-maintenance; do
     [ -d "docs/$d" ] && git mv "docs/$d" ".claude/$d"
   done
   ```
3. ALM 파일과 CLAUDE.md 이동:
   ```bash
   git mv docs/lifecycle.md docs/tech-debt-registry.md docs/kpi-definitions.md .claude/ 2>/dev/null || true
   [ -f CLAUDE.md ] && git mv CLAUDE.md .claude/CLAUDE.md
   ```
4. `.gitignore`의 `.claude/local/` 라인은 다음 세션 시작 시 SessionStart 훅이
   자동으로 `.claude/`로 교체한다 (수동 작업 불필요).
5. 추적이 필요한 산출물(예: PRD)은 다시 `.claude/` 밖으로 꺼내면 된다:
   `git mv .claude/02-planning/prd.md docs/02-planning/prd.md`

### Added (마켓플레이스 정리, 함께 출시)
- `.claude-plugin/marketplace.json` — 이 저장소를 Claude Code 플러그인
  마켓플레이스로 노출. 사용자는 `/plugin marketplace add shaul1991/shaul-plugin`
  → `/plugin install project-lifecycle@shaul-plugin` 으로 설치 가능.
- README 설치 섹션을 마켓플레이스 / 로컬 마켓플레이스(개발용)
  두 가지 경로로 정리.

### Removed (마켓플레이스 정리, 함께 출시)
- `claude-code-plugin/project-lifecycle.plugin` — `.plugin` zip 아카이브.
  마켓플레이스가 디렉토리 source(`./claude-code-plugin/project-lifecycle`)를
  직접 사용하므로 더 이상 필요 없습니다. 과거 stale-archive 회귀의
  진원지였습니다.
- `scripts/build-plugin.sh` — 위 아카이브 재생성을 위한 단일 빌드 스크립트.
- `.github/workflows/plugin-archive-check.yml` — 아카이브-소스 정합성 CI 가드.

## [0.3.1] — 2026-04-28

### Fixed
- Rebuild `claude-code-plugin/project-lifecycle.plugin` so it ships with
  `hooks/hooks.json` and `hooks/bootstrap-local.sh`. Previous archives were
  cut before commit `4f910de` and silently lost the `SessionStart`
  auto-bootstrap that the README advertises.
- Pick up earlier mojibake fixes (`97c3810`, `08f5b7b`) that had not made it
  into the published archive: `agents/alm-manager.md`,
  `skills/governance/references/execution-plan-template.md`, and the
  refreshed phase `SKILL.md` files.

### Added
- `scripts/build-plugin.sh` — single source of truth for producing the
  plugin archive. Self-checks for required entries (`hooks/`,
  `.claude-plugin/plugin.json`) and byte-identical equivalence with the
  source tree, so a stale archive can no longer be committed by accident.
- `.github/workflows/plugin-archive-check.yml` — CI guard that re-runs the
  build and fails the job if `claude-code-plugin/project-lifecycle.plugin`
  drifts from `claude-code-plugin/project-lifecycle/`.
- `CHANGELOG.md` (this file).

### Changed
- README install instructions now spell out the working-directory
  assumption and provide an absolute-path fallback.
- README repo layout and contribution guide now document `scripts/`,
  `CHANGELOG.md`, and `.github/workflows/`, including the obligation to
  rebuild the archive via `scripts/build-plugin.sh` after editing the
  plugin source.

## [0.3.0] — 2026-04-28

### Added
- `SessionStart` hook (`hooks/bootstrap-local.sh`) that, in any user
  project that is a git repository, creates `.claude/local/plans/` and
  appends `.claude/local/` to `.gitignore` (idempotent, no-op outside git).

### Changed
- Per-branch execution-plan workspace lives at
  `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md`. The plugin
  repo applies the same `.claude/local/` convention to itself.
- Documentation hardened end-to-end (`README.md`, governance skill,
  agent definitions) with mojibake fixes for execution-plan template and
  the `alm-manager` agent.

### Added (repository housekeeping)
- Repository-root `README.md` as the public landing page.

## [0.2.0] — 2026-04-27

### Changed
- Switched execution-plan storage from a flat `docs/` location to a
  per-branch workspace under `.claude/local/plans/<branch>/`, isolating
  drafts per branch and keeping them out of git history.

## [0.1.0] — 2026-04-27

### Added
- Initial release of the `project-lifecycle` plugin: 9 phase skills
  (`00-setup` … `08-maintenance`), 6 cross-cutting skills (`governance`,
  `dashboard`, `sync-check`, `impact-analysis`, `debt-collector`,
  `gate-keeper`), 14 expert agents, and the Plan-Review-Execute-Reverify
  governance flow.
