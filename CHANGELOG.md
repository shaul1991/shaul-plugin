# Changelog

All notable changes to the **project-lifecycle** Claude Code plugin are tracked
here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
