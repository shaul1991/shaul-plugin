# Changelog

All notable changes to the **project-lifecycle** Claude Code plugin are tracked
here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.10.0] — 2026-04-30

### Added — 외부 트래커 옵션 통합 (Plane Opensource)
- **`.claude/integrations.json` 한 파일로 외부 트래커 활성·비활성**.
  `tracker.primary` = `null`(or 파일 부재) → v0.9.0 비트단위 동일 (기존
  사용자 영향 0). `"plane"` 으로 설정 시 4개 도메인 자동 push.
- **연동 4개 도메인** (provider 안에서 도메인별 `mode` 상속/오버라이드):
  - `docs/issues/<slug>.md` ↔ Plane Issue (root) — frontmatter 매핑
  - `docs/alm/lifecycle.md` ↔ Plane Module + Module Issue per Phase —
    file-end `<!-- plane-sync:lifecycle ... -->` 주석 블록 매핑
  - `docs/alm/tech-debt-registry.md` ↔ Plane Issue per `TD-NNN`
    (label=`tech-debt` + severity) — file-end 주석 블록 매핑
  - `.claude/local/plans/<branch>/<NN-phase>/execution-plan.md` ↔ Plane
    Sub-issue (parent = lifecycle Phase Issue) — frontmatter 매핑
- **모드 3종**: `local` (default, 동기화 X) / `plane` (Plane 마스터) /
  `both` (local 마스터). v1 push 동작은 `plane`/`both` 동일 — 의미적
  분리는 v0.11+ pull 기능 슬롯.
- **Fail-open 정책** (secret-guard fail-closed 와 의도적 대비). 네트워크
  실패·5xx·토큰 부재 모두 stderr 경고 + skip — 사용자 작업은 *블록되지
  않는다*. 401(잘못된 토큰)은 명확 메시지로 sync 비활성.
- **신규 훅 / 라이브러리**:
  - `hooks/plane-watch.sh` (SessionStart, read-only 상태 보고)
  - `hooks/plane-sync.sh` (PostToolUse `Edit|Write`, 자동 push)
  - `hooks/lib/plane_sync.py` (config 파싱·HTTP·frontmatter·도메인 sync 의 단일 두뇌)
- **신규 템플릿**:
  - `hooks/integrations-template.json` — `.claude/integrations.json` 시작 샘플
  - `hooks/plane-secret-template.json` — `.claude/local/plane.secret.json` 시작 샘플
- **신규 스킬** `/integrations` — 외부 트래커 활성 절차·상태 점검·트러블슈팅 안내.
  자동 push 는 *훅 책임*, 본 스킬은 read-only 가이드 (헌장 D7).
- **신규 헌장** `docs/direction/2026-04-30-plane-integration-charter.md`
  — 본 통합의 사용자 원문·5 원칙·D1~D16 결정·미래 12 가드레일·도메인 매핑·모드 동작.
- **토큰 우선순위**: `CLAUDE_PLUGIN_PLANE_TOKEN` (env) > `PLANE_API_TOKEN`
  (env) > `.claude/local/plane.secret.json` (파일) > 없음 (skip).
- **세션 단위 일시 비활성**: `CLAUDE_PLUGIN_PLANE_SYNC=off|0|false|no`.

### Changed
- **`hooks/hooks.json`** — `SessionStart` 에 `plane-watch.sh` 추가,
  **`PostToolUse` 매처 신설** (`Edit|Write` → `plane-sync.sh`).
- **`hooks/secret-guard-template.json`** + **`hooks/secret-guard.sh`
  내장 DEFAULTS** — `always_block` 에 `*.secret.json`, `plane.secret.json`
  추가. `.claude/local/plane.secret.json` 이 자동 차단됨 (basename 매칭).
  헌장 D14: v0.7.0 헌장 D7 ("기본값 확장은 헌장 갱신 후") 절차에 따른 추가.
- **`00-setup` SKILL Step 9 신설** — "외부 트래커 연동 권유 (옵션)".
  자동 활성화 X, 사용자가 원할 때 `/integrations` 안내.
- **`dashboard` SKILL Step 3-1** — 활성 트래커 한 줄 표시 (read-only 분기).
- **`governance` SKILL** — "PLAN 사전 준비" 절에 한 줄 추가: 외부 트래커
  활성 시 PostToolUse 가 자동 push, governance 는 직접 쓰지 않음 (D7).
- **`debt-collector` SKILL Step 4 끝** — 신규 `TD-NNN` 자동 push 안내.
- **`03-architecture` references/tech-debt-registry-template.md** — 파일
  끝에 `<!-- plane-sync:tech-debt -->` 빈 블록 자리 (옵션, 비활성 시 무해).
- 플러그인 description / keywords 에 `tracker-integration`, `plane`,
  `plane-opensource`, `integrations-json`, `external-tracker`, `issue-sync`,
  `posttooluse` 추가.

### Migration (v0.9.0 → v0.10.0)
**기본은 무액션.** v0.10.0 으로 업그레이드해도 `.claude/integrations.json`
을 만들지 않는 한 v0.9.0 동작과 비트단위 동일 (헌장 D1).

외부 트래커를 켜고 싶다면 `/integrations` 스킬을 호출하거나 다음 절차를
*사용자 명시적으로* 진행:

```bash
# 1. 비-시크릿 통합 설정
cp "${CLAUDE_PLUGIN_ROOT}/hooks/integrations-template.json" .claude/integrations.json
# → workspace_slug, project_id, host 를 직접 편집

# 2. 시크릿 토큰 (gitignore 차단 영역)
mkdir -p .claude/local
cp "${CLAUDE_PLUGIN_ROOT}/hooks/plane-secret-template.json" .claude/local/plane.secret.json
chmod 600 .claude/local/plane.secret.json
# → api_token, issued_at 직접 편집

# 3. 첫 세션은 dry_run: true 권장 (헌장 D16) — stderr 로 어떤 push 가 일어날지 확인
```

자세한 절차·트러블슈팅은 `claude-code-plugin/project-lifecycle/skills/integrations/SKILL.md`
참조.

## [0.9.0] — 2026-04-29

### Changed — Asset Classification 재정의 (BREAKING for v0.8.x adopters)
- **`.claude/` = *Claude/플러그인 사용 설정 전용*, 모든 문서는 `docs/` 로
  통일.** v0.8.0 의 *공유/운영/로컬 3계층* 패턴이 의미적으로는 명확했으나
  (1) symlink 가 macOS/Linux 환경 의존, (2) `.claude/` 와 `docs/` 양쪽에
  자산이 분산되어 *어디를 봐야 하는지* 혼란, (3) 운영 자산도 결국
  *문서 형태* 라 docs/ 통합이 자연스러움 — 단순화.
- **`.claude/` 잔류**: `CLAUDE.md`, `secret-guard.json`, `settings.json`
  (+ `local/`, `settings.local.json` 로컬). 셋 다 *Claude Code/플러그인이
  자동 로드하는 설정* — 문서 형태가 아님.
- **`docs/` 카테고리** (사용자 결정, *권장* 매핑):
  - `docs/knowledge/` — 사내 4종 (용어집·기획요구·기술요구·API흐름)
  - `docs/architecture/` — Phase 3 산출물
  - `docs/operations/` — Phase 8 산출물
  - `docs/team/` — 프로젝트 메타·팀 컨벤션
  - `docs/policies/` — Lightweight ADR
  - `docs/alm/` — ALM 추적 자산 (lifecycle, tech-debt-registry,
    kpi-definitions) **(NEW)**
  - `docs/issues/` — 외부 트래커 대체 **(NEW)**
- **symlink 패턴 폐기.** v0.8.0 의 `.claude/<원래>` → `docs/<새>` 호환
  symlink 는 도입하지 않는다 (헌장 D3). 플러그인 step·skill·에이전트의
  cross-ref 는 `docs/<name>` 로 직접.
- **`.gitignore` 단순화**. negate 룰이 7~12 개에서 *3 개* 로 축소:
  ```gitignore
  .claude/*
  !.claude/CLAUDE.md
  !.claude/secret-guard.json
  !.claude/settings.json
  .claude/settings.local.json
  ```

### Added
- `docs/direction/2026-04-29-claude-as-settings-only-charter.md` — 본
  정책의 사용자 원문 요구·도출 원칙·설계 결정·미래 변경 가드레일을
  보존하는 헌장. v0.8.0 헌장의 D3·D4 폐기 명시.
- `references/asset-location-template.md` — 신규 분류표·신규 프로젝트
  초기 셋업·기존 v0.8.x 마이그레이션 8단계·자주 묻는 질문 (NEW).

### Changed
- v0.8.0 헌장 `2026-04-29-three-tier-asset-charter.md` 상태를 *Superseded
  by 2026-04-29-claude-as-settings-only-charter.md* 로 갱신. 분류 사유 등
  대부분의 결정(D1·D2·D5·D9·D10·D12)은 본 v0.9.0 에서도 유효.
- `00-setup` SKILL Step 8 재작성. 분류 원칙 안내 → 권장 분류표 → 의사
  확인 → 마이그레이션 절차 → cross-reference 갱신 → 마무리 안내 6 단계.
- `setup-coordinator` 행동 원칙 #6 갱신 (v0.8.0+ → v0.9.0+).
- 플러그인 description 갱신. 키워드 변경: `three-tier-classification`,
  `asset-promotion`, `gitignore-negate`, `symlink` 제거 → `asset-location`,
  `config-vs-docs`, `claude-as-settings` 추가.

### Migration (v0.8.x → v0.9.0)
v0.8.0 의 *3계층 + symlink* 를 적용한 프로젝트의 마이그레이션. **자동
실행 X** — 사용자가 명시적으로 진행.

```bash
# 1. 새 폴더
mkdir -p docs/alm docs/issues

# 2. 운영 자산 이동
mv .claude/lifecycle.md docs/alm/lifecycle.md
mv .claude/tech-debt-registry.md docs/alm/tech-debt-registry.md
mv .claude/kpi-definitions.md docs/alm/kpi-definitions.md
mv .claude/issues docs/issues

# 3. 호환 symlink 제거
cd .claude && rm -f 00-setup 03-architecture 08-maintenance policies knowledge && cd ..

# 4. .gitignore 를 위 단순화 룰로 교체

# 5. cross-reference 일괄 갱신 (sed 명령은 references 참조)

# 6. .claude/CLAUDE.md ALM 표 재구성
```

상세 8단계는 `claude-code-plugin/project-lifecycle/skills/00-setup/references/asset-location-template.md` §"기존 v0.8.x 프로젝트의 마이그레이션" 참조.

### Notes
- **참조 구현**: pkpk-api(`atms-backend/api`) 가 v0.9.0 첫 적용 사례.
  커밋 `b6e07a2` — 운영 자산 4종 docs/ 이동 + symlink 5개 폐기 +
  cross-ref 8 파일 일괄 갱신. git 이 `mv` 를 *rename* 으로 자동 인식하여
  history 보존됨.
- **v0.7.x 이전 사용자** (`.claude/` 전체 차단)는 변경 없이 동작 가능.
  하위 호환 보장.
- **플러그인 내부 정합성**: 다른 phase SKILL 들의 `.claude/<x>/` 가정 은
  본 릴리즈에서 *동시 갱신하지 않음*. 향후 라운드에서 점진 갱신 예정.
  사용자 프로젝트가 v0.9.0 정책을 적용해도 *기존 SKILL 내부 참조* 는
  심볼릭 링크 없이도 docs/ 위치를 찾을 수 있도록 SKILL 본문이 자율 동작
  (예: 산출물을 *새로 작성* 시 `docs/<name>/<file>.md` 로 작성 권장).

## [0.8.0] — 2026-04-29

### Added — Asset Classification
- **사내 자산 3계층 분류 (`00-setup` Step 8 신설).** ALM 산출물을
  *공유 자산* / *운영 자산* / *로컬 전용* 3 계층으로 분류하는
  표준 가이드. v0.7.x 까지의 `.claude/` 전체 차단 패턴은 *그대로 유지
  가능* (하위 호환). 적극 활용을 원하는 팀에 한해 권장:
  - **공유 자산** → `docs/<name>/` (실체) + `.claude/<name>` 심볼릭 링크.
    git 추적 ON. 외부 협업·온보딩 가치 큰 *읽기 자료* (architecture,
    operations, team, policies, knowledge).
  - **운영 자산** → `.claude/` 직속 + `.gitignore` negate 룰. git 추적
    ON. 플러그인이 *작동을 위해 읽고 쓰는* 자산 (lifecycle.md,
    tech-debt-registry.md, kpi-definitions.md, issues/, secret-guard.json,
    settings.json, CLAUDE.md).
  - **로컬 전용** → `.claude/local/`, `.claude/settings.local.json`.
    git 차단 유지. 일시 작업·개인 설정.
- **신규 참조 템플릿
  `references/three-tier-classification-template.md`** — 분류표,
  마이그레이션 명령 시퀀스(mv + ln -s), `.gitignore` 패턴 시작 샘플,
  자주 묻는 질문.
- `docs/direction/2026-04-29-three-tier-asset-charter.md` — 본 분류 정책의
  사용자 원문 요구·도출 원칙·설계 결정·미래 변경 가드레일을 보존하는 헌장.
- **참조 구현**: pkpk-api(`atms-backend/api`) 프로젝트가 첫 적용 사례.
  - 4 디렉토리 승격 (`03-architecture` → `architecture`, `08-maintenance`
    → `operations`, `00-setup` → `team`, `policies` 동명).
  - 7 운영 자산 negate 추적 활성화.
  - 5 호환 심볼릭 링크 (`mode 120000` 으로 git 정상 추적 검증).
  - 0 sync drift (단일 진실 + symlink).

### Changed
- **`00-setup` SKILL Step 8 신설.** 분류 안내 → 권장 매핑 → 의사 확인
  → 승격 절차 → 운영 자산 추적 활성화 → 마무리 안내 6 단계로 구성.
  자동 승격은 *하지 않는다* (헌장 D6) — 사용자가 명시 결정한 디렉토리만
  옮긴다.
- 플러그인 description 갱신 — v0.8.0 의 3계층 분류 한 줄 추가.
- 키워드 추가: `three-tier-classification`, `asset-promotion`,
  `gitignore-negate`, `symlink`.

### Migration (v0.7.x → v0.8.0)
별도 작업 *불필요*. 머지 후 신규 프로젝트의 `00-setup` 호출 시 Step 8 이
자동 안내된다. 기존 프로젝트는 자발적 승격 시점에 다음 절차:

```bash
# 예: .claude/03-architecture → docs/architecture (4 디렉토리 모두 동일 패턴)
mv .claude/03-architecture docs/architecture
ln -s ../docs/architecture .claude/03-architecture

# .gitignore 룰 교체 (.claude/ 한 줄 → 와일드카드 + 명시 negate)
# .claude/*
# !.claude/CLAUDE.md
# !.claude/lifecycle.md
# !.claude/tech-debt-registry.md
# !.claude/kpi-definitions.md
# !.claude/issues/
# !.claude/secret-guard.json
# !.claude/settings.json
# !.claude/00-setup
# !.claude/03-architecture
# !.claude/08-maintenance
# !.claude/policies
# !.claude/knowledge
# .claude/settings.local.json
```

상세 가이드는
`claude-code-plugin/project-lifecycle/skills/00-setup/references/three-tier-classification-template.md`
참조.

### Notes
- **하위 호환 보장.** v0.7.x 이전의 `.claude/` 전체 차단 사용자는
  변경 없이 동작. 본 분류는 *opt-in*.
- **자동 마이그레이션 스크립트 ship X** (헌장 D7). 사용자 영역 침범
  회피 — 명령 시퀀스 *제시*만.
- **Windows 호환성** (헌장 D11). symlink 미지원 환경에선 `mklink /D`
  또는 `git config core.symlinks=true` 가 필요. 플러그인은 강제하지 않음.

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
