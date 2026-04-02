#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

resolve_python_runner() {
  if [[ -x "${ROOT_DIR}/.venv/bin/python" ]]; then
    printf "%s" "${ROOT_DIR}/.venv/bin/python"
    return
  fi

  if command -v python3 > /dev/null 2>&1; then
    command -v python3
    return
  fi

  echo "Python 3 is required to format the project." >&2
  exit 1
}

PYTHON_RUNNER="$(resolve_python_runner)"

run_python_module() {
  local module_name="$1"
  shift

  "${PYTHON_RUNNER}" -m "${module_name}" "$@"
}

run_fixing_pre_commit_hook() {
  local hook_id="$1"
  shift

  if run_python_module pre_commit run --all-files "${hook_id}" "$@"; then
    return
  fi

  run_python_module pre_commit run --all-files "${hook_id}" "$@"
}

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" > /dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    exit 1
  fi
}

cd "${ROOT_DIR}"

run_fixing_pre_commit_hook end-of-file-fixer
run_fixing_pre_commit_hook trailing-whitespace
run_fixing_pre_commit_hook mixed-line-ending

run_python_module ruff format app tests migrations
run_python_module ruff check app tests migrations --fix

run_fixing_pre_commit_hook prettier-write --hook-stage manual
run_fixing_pre_commit_hook shfmt-write --hook-stage manual

require_command terraform
terraform -chdir=terraform fmt -recursive
