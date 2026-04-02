#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUALITY_LAYER="${1:-all}"

resolve_python_runner() {
  if [[ -x "${ROOT_DIR}/.venv/bin/python" ]]; then
    printf "%s" "${ROOT_DIR}/.venv/bin/python"
    return
  fi

  if command -v python3 > /dev/null 2>&1; then
    command -v python3
    return
  fi

  echo "Python 3 is required to run quality checks." >&2
  exit 1
}

PYTHON_RUNNER="$(resolve_python_runner)"

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" > /dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    exit 1
  fi
}

run_python_module() {
  local module_name="$1"
  shift

  "${PYTHON_RUNNER}" -m "${module_name}" "$@"
}

run_python_cli() {
  local command_name="$1"
  shift

  if [[ -x "${ROOT_DIR}/.venv/bin/${command_name}" ]]; then
    "${ROOT_DIR}/.venv/bin/${command_name}" "$@"
    return
  fi

  require_command "${command_name}"
  "${command_name}" "$@"
}

copy_repo_snapshot() {
  local destination_dir="$1"

  "${PYTHON_RUNNER}" - "${destination_dir}" << 'PY'
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

root_dir = Path.cwd()
destination_dir = Path(sys.argv[1])

completed = subprocess.run(
    ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
    check=True,
    stdout=subprocess.PIPE,
    cwd=root_dir,
)

for raw_path in completed.stdout.split(b"\0"):
    if not raw_path:
        continue

    relative_path = Path(raw_path.decode("utf-8", "surrogateescape"))
    source_path = root_dir / relative_path

    if not source_path.is_file():
        continue

    target_path = destination_dir / relative_path
    target_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_path, target_path)
PY
}

run_pre_commit_hooks() {
  local hook_id

  for hook_id in "$@"; do
    run_python_module pre_commit run --all-files "${hook_id}"
  done
}

run_read_only_text_hygiene_check() {
  printf "%-72s" "text hygiene (read-only)"

  if "${PYTHON_RUNNER}" ./scripts/check-text-hygiene.py; then
    echo "Passed"
    return
  fi

  echo "Failed"
  exit 1
}

run_fast_checks() {
  echo "==> Fast quality checks"

  run_pre_commit_hooks check-merge-conflict
  run_read_only_text_hygiene_check
  run_pre_commit_hooks \
    prettier-check \
    markdownlint-cli2 \
    yamllint \
    shfmt-check \
    shellcheck \
    actionlint \
    hadolint \
    dotenv-linter \
    ruff-format \
    ruff-check
}

run_python_quality_checks() {
  echo "==> Python quality checks"

  run_python_module pylint --rcfile=/dev/null app tests migrations
  run_python_module radon cc app tests migrations
  run_python_module radon mi app tests migrations
}

run_gitleaks_check() {
  local scan_mode
  local snapshot_dir
  local exit_code

  scan_mode="${GITLEAKS_MODE:-dir}"

  if [[ "${scan_mode}" == "git" ]]; then
    ./scripts/run-quality-tool.sh gitleaks git --no-banner --redact --log-opts="--all" .
    return
  fi

  snapshot_dir="$(mktemp -d)"

  copy_repo_snapshot "${snapshot_dir}"
  if ./scripts/run-quality-tool.sh gitleaks dir --no-banner --redact "${snapshot_dir}"; then
    rm -rf -- "${snapshot_dir}"
    return
  fi

  exit_code=$?
  rm -rf -- "${snapshot_dir}"
  return "${exit_code}"
}

run_lychee_check() {
  ./scripts/run-quality-tool.sh lychee \
    --no-progress \
    --format compact \
    --exclude-loopback \
    --exclude '^mailto:' \
    --exclude '^https?://playcatch\.local(:[0-9]+)?($|/)' \
    README.md CHANGELOG.md docs
}

run_security_checks() {
  echo "==> Security validation"

  run_gitleaks_check
  run_python_cli pip-audit -r requirements.txt -r requirements-dev.txt
  run_lychee_check
  run_python_cli bandit -q -r app migrations
}

validate_rendered_manifest() {
  local manifest_path="$1"

  "${PYTHON_RUNNER}" - "${manifest_path}" << 'PY'
from __future__ import annotations

import sys

import yaml

manifest_path = sys.argv[1]

with open(manifest_path, "r", encoding="utf-8") as manifest_file:
    documents = [document for document in yaml.safe_load_all(manifest_file) if document is not None]

if not documents:
    raise SystemExit(f"No manifest documents were rendered from {manifest_path}.")

for index, document in enumerate(documents, start=1):
    if not isinstance(document, dict):
        raise SystemExit(
            f"Rendered document {index} in {manifest_path} is not a YAML mapping."
        )

    missing_fields = [field for field in ("apiVersion", "kind") if field not in document]
    metadata = document.get("metadata")
    metadata_name = metadata.get("name") if isinstance(metadata, dict) else None

    if missing_fields:
        raise SystemExit(
            f"Rendered document {index} in {manifest_path} is missing fields: "
            f"{', '.join(missing_fields)}"
        )

    if not metadata_name:
        raise SystemExit(
            f"Rendered document {index} in {manifest_path} is missing metadata.name."
        )
PY
}

run_infra_checks() {
  local helm_render_file
  local helm_external_secret_file
  local istio_render_file
  local terraform_data_dir

  echo "==> Infrastructure validation"

  require_command docker
  require_command helm
  require_command terraform

  docker compose config > /dev/null

  helm lint helm/music-platform

  helm_render_file="$(mktemp)"
  helm_external_secret_file="$(mktemp)"
  istio_render_file="$(mktemp)"
  terraform_data_dir="$(mktemp -d)"

  trap 'rm -f "${helm_render_file}" "${helm_external_secret_file}" "${istio_render_file}"; rm -rf "${terraform_data_dir}"' RETURN

  helm template music-platform helm/music-platform > "${helm_render_file}"
  validate_rendered_manifest "${helm_render_file}"

  helm template music-platform helm/music-platform \
    --set db.existingSecret=runtime-db-secret > "${helm_external_secret_file}"
  validate_rendered_manifest "${helm_external_secret_file}"

  ./scripts/render-istio-manifests.sh > "${istio_render_file}"
  validate_rendered_manifest "${istio_render_file}"

  terraform -chdir=terraform fmt -check -recursive
  TF_DATA_DIR="${terraform_data_dir}" terraform -chdir=terraform init -backend=false -reconfigure
  TF_DATA_DIR="${terraform_data_dir}" terraform -chdir=terraform validate
}

run_runtime_checks() {
  echo "==> Runtime validation"

  require_command docker

  run_python_module pytest -q tests
  run_python_module compileall app
  docker build -t music-platform-api:quality .
}

cd "${ROOT_DIR}"

case "${QUALITY_LAYER}" in
  fast)
    run_fast_checks
    ;;
  python)
    run_python_quality_checks
    ;;
  security)
    run_security_checks
    ;;
  infra)
    run_infra_checks
    ;;
  runtime)
    run_runtime_checks
    ;;
  all)
    run_fast_checks
    run_python_quality_checks
    run_security_checks
    run_infra_checks
    run_runtime_checks
    ;;
  *)
    echo "Unknown quality layer: ${QUALITY_LAYER}" >&2
    echo "Use one of: fast, python, security, infra, runtime, all" >&2
    exit 1
    ;;
esac
