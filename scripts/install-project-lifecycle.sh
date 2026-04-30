#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="project-lifecycle"
MARKETPLACE_NAME="shaul-plugin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PRIMARY=""
PROJECT=""
SOURCE="${REPO_ROOT}"
WITH_SECONDARY=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  scripts/install-project-lifecycle.sh --primary claude --project /path/to/project [--with-secondary]
  scripts/install-project-lifecycle.sh --primary codex  --project /path/to/project [--with-secondary]

Options:
  --primary claude|codex   Tool that owns final review/merge decisions.
  --project PATH           Target project where local runtime config is written.
  --source SOURCE          Marketplace source. Defaults to this repository root.
                           Examples: /path/to/shaul-plugin, shaul1991/shaul-plugin
  --with-secondary         Also register the opposite tool as an optional reviewer.
  --dry-run                Print actions without changing tool config or project files.
  -h, --help               Show this help.

Install model:
  Claude primary: registers marketplace, installs project-lifecycle in Claude Code,
                  and writes <project>/.claude/project-lifecycle.json.
  Codex primary:  registers marketplace in Codex and writes
                  <project>/.codex/project-lifecycle.json. Then install from
                  Codex /plugins because Codex CLI currently exposes marketplace
                  management, not a plugin install subcommand.
EOF
}

info() {
  printf '[project-lifecycle] %s\n' "$*"
}

warn() {
  printf '[project-lifecycle] warning: %s\n' "$*" >&2
}

die() {
  printf '[project-lifecycle] error: %s\n' "$*" >&2
  exit 1
}

quote_cmd() {
  printf '%q ' "$@"
  printf '\n'
}

run_required() {
  info "+ $(quote_cmd "$@")"
  if [ "${DRY_RUN}" -eq 1 ]; then
    return 0
  fi
  "$@"
}

run_best_effort() {
  info "+ $(quote_cmd "$@")"
  if [ "${DRY_RUN}" -eq 1 ]; then
    return 0
  fi
  if "$@"; then
    return 0
  fi
  warn "command failed; continuing because it may already be configured"
}

require_tool() {
  local tool="$1"
  command -v "${tool}" >/dev/null 2>&1 || die "required CLI not found: ${tool}"
}

normalize_project() {
  local path="$1"
  [ -n "${path}" ] || die "--project is required"
  [ -d "${path}" ] || die "project path does not exist: ${path}"
  (cd "${path}" && pwd)
}

ensure_gitignore_line() {
  local project="$1"
  local line="$2"
  local gitignore="${project}/.gitignore"

  if [ "${DRY_RUN}" -eq 1 ]; then
    info "would ensure ${gitignore} contains ${line}"
    return 0
  fi

  if [ -f "${gitignore}" ]; then
    case "${line}" in
      ".claude/")
        grep -qxF ".claude/" "${gitignore}" && return 0
        grep -qxF ".claude" "${gitignore}" && return 0
        grep -qxF ".claude/*" "${gitignore}" && return 0
        ;;
      ".codex/")
        grep -qxF ".codex/" "${gitignore}" && return 0
        grep -qxF ".codex" "${gitignore}" && return 0
        grep -qxF ".codex/*" "${gitignore}" && return 0
        ;;
      *)
        grep -qxF "${line}" "${gitignore}" && return 0
        ;;
    esac
  fi

  if [ -f "${gitignore}" ] && [ -s "${gitignore}" ]; then
    tail -c 1 "${gitignore}" | grep -q '^$' || printf '\n' >>"${gitignore}"
  fi
  printf '%s\n' "${line}" >>"${gitignore}"
}

write_runtime_config() {
  local project="$1"
  local primary="$2"
  local secondary="$3"
  local runtime_dir runtime_config plans_dir parallel_dir

  if [ "${primary}" = "claude" ]; then
    runtime_dir="${project}/.claude"
    runtime_config="${runtime_dir}/project-lifecycle.json"
    plans_dir=".claude/local/plans"
    parallel_dir=".claude/local/parallel-runs"
    ensure_gitignore_line "${project}" ".claude/"
  else
    runtime_dir="${project}/.codex"
    runtime_config="${runtime_dir}/project-lifecycle.json"
    plans_dir=".codex/local/plans"
    parallel_dir=".codex/local/parallel-runs"
    ensure_gitignore_line "${project}" ".codex/"
  fi

  info "primary runtime: ${primary}"
  info "secondary runtime: ${secondary}"
  info "target config: ${runtime_config}"

  if [ "${DRY_RUN}" -eq 1 ]; then
    info "would write runtime config"
    return 0
  fi

  mkdir -p "${runtime_dir}"
  cat >"${runtime_config}" <<EOF
{
  "schema_version": 1,
  "plugin": "${PLUGIN_NAME}",
  "marketplace": "${MARKETPLACE_NAME}",
  "primary": "${primary}",
  "secondary": "${secondary}",
  "source": "${SOURCE}",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "local": {
    "plans": "${plans_dir}",
    "parallel_runs": "${parallel_dir}"
  }
}
EOF
}

register_claude_primary() {
  require_tool claude
  run_best_effort claude plugin marketplace add "${SOURCE}"
  run_best_effort claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}"
}

register_codex_primary() {
  require_tool codex
  run_best_effort codex plugin marketplace add "${SOURCE}"
}

register_secondary() {
  local secondary="$1"
  if [ "${secondary}" = "none" ]; then
    return 0
  fi

  if [ "${secondary}" = "claude" ]; then
    if command -v claude >/dev/null 2>&1; then
      run_best_effort claude plugin marketplace add "${SOURCE}"
    else
      warn "secondary Claude Code registration skipped; claude CLI not found"
    fi
  else
    if command -v codex >/dev/null 2>&1; then
      run_best_effort codex plugin marketplace add "${SOURCE}"
    else
      warn "secondary Codex registration skipped; codex CLI not found"
    fi
  fi
}

print_next_steps() {
  local project="$1"
  local primary="$2"
  local secondary="$3"

  cat <<EOF

[project-lifecycle] Done.

Install source:
  ${SOURCE}

Target project:
  ${project}

Runtime:
  primary=${primary}
  secondary=${secondary}

Next steps:
EOF

  if [ "${primary}" = "codex" ]; then
    cat <<EOF
  1. Start Codex in the target project:
       codex -C "${project}"
  2. Open /plugins.
  3. Select marketplace "${MARKETPLACE_NAME}".
  4. Install "${PLUGIN_NAME}".
  5. Start a new Codex session and invoke a bundled skill such as \$governance.
EOF
  else
    cat <<EOF
  1. Start Claude Code in the target project:
       claude --add-dir "${project}"
  2. Start a fresh session so plugin hooks and skills reload.
  3. Invoke a bundled skill such as /governance or "프로젝트 설정".
EOF
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --primary)
      PRIMARY="${2:-}"
      shift 2
      ;;
    --project)
      PROJECT="${2:-}"
      shift 2
      ;;
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --with-secondary)
      WITH_SECONDARY=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[ "${PRIMARY}" = "claude" ] || [ "${PRIMARY}" = "codex" ] || die "--primary must be claude or codex"
PROJECT="$(normalize_project "${PROJECT}")"

SECONDARY="none"
if [ "${WITH_SECONDARY}" -eq 1 ]; then
  if [ "${PRIMARY}" = "claude" ]; then
    SECONDARY="codex"
  else
    SECONDARY="claude"
  fi
fi

if [ "${PRIMARY}" = "claude" ]; then
  register_claude_primary
else
  register_codex_primary
fi

register_secondary "${SECONDARY}"
write_runtime_config "${PROJECT}" "${PRIMARY}" "${SECONDARY}"
print_next_steps "${PROJECT}" "${PRIMARY}" "${SECONDARY}"
