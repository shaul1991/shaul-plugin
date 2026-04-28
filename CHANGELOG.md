# Changelog

All notable changes to the **project-lifecycle** Claude Code plugin are tracked
here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `.claude-plugin/marketplace.json` — 이 저장소를 Claude Code 플러그인
  마켓플레이스로 노출. 사용자는 `/plugin marketplace add shaul1991/shaul-plugin`
  → `/plugin install project-lifecycle@shaul-plugin` 으로 설치 가능.
- README 설치 섹션을 마켓플레이스 / 로컬 마켓플레이스(개발용)
  두 가지 경로로 정리.

### Removed
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
