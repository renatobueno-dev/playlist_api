#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${ROOT_DIR}/.tools/bin"
TOOL_NAME="${1:-}"

if [[ -z "${TOOL_NAME}" ]]; then
  echo "Usage: $0 <tool-name> [tool-args...]" >&2
  exit 1
fi

shift

normalize_os() {
  case "$(uname -s)" in
    Darwin)
      echo "darwin"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      echo "Unsupported operating system: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

normalize_arch() {
  case "$(uname -m)" in
    x86_64 | amd64)
      echo "x86_64"
      ;;
    arm64 | aarch64)
      echo "arm64"
      ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

download_file() {
  local url="$1"
  local destination="$2"
  local temp_file="${destination}.tmp"

  mkdir -p "$(dirname "${destination}")"
  curl --retry 5 --retry-all-errors --retry-delay 2 -fsSL "${url}" -o "${temp_file}"
  mv "${temp_file}" "${destination}"
}

extract_tar_archive() {
  local archive_path="$1"
  local extract_dir="$2"

  rm -rf "${extract_dir}"
  mkdir -p "${extract_dir}"
  tar -xzf "${archive_path}" -C "${extract_dir}"
}

ensure_hadolint() {
  local os_name
  local arch_name
  local asset_name
  local binary_path
  local version="v2.14.0"

  os_name="$(normalize_os)"
  arch_name="$(normalize_arch)"

  case "${os_name}-${arch_name}" in
    linux-x86_64)
      asset_name="hadolint-linux-x86_64"
      ;;
    linux-arm64)
      asset_name="hadolint-linux-arm64"
      ;;
    darwin-x86_64)
      asset_name="hadolint-macos-x86_64"
      ;;
    darwin-arm64)
      asset_name="hadolint-macos-arm64"
      ;;
    *)
      echo "Unsupported hadolint platform: ${os_name}-${arch_name}" >&2
      exit 1
      ;;
  esac

  binary_path="${TOOLS_DIR}/${asset_name}"

  if [[ ! -x "${binary_path}" ]]; then
    download_file \
      "https://github.com/hadolint/hadolint/releases/download/${version}/${asset_name}" \
      "${binary_path}"
    chmod +x "${binary_path}"
  fi

  printf "%s" "${binary_path}"
}

ensure_gitleaks() {
  local os_name
  local arch_name
  local asset_name
  local version="8.30.1"
  local archive_path
  local extract_dir
  local binary_path

  os_name="$(normalize_os)"
  arch_name="$(normalize_arch)"

  case "${os_name}-${arch_name}" in
    linux-x86_64)
      asset_name="gitleaks_${version}_linux_x64.tar.gz"
      ;;
    linux-arm64)
      asset_name="gitleaks_${version}_linux_arm64.tar.gz"
      ;;
    darwin-x86_64)
      asset_name="gitleaks_${version}_darwin_x64.tar.gz"
      ;;
    darwin-arm64)
      asset_name="gitleaks_${version}_darwin_arm64.tar.gz"
      ;;
    *)
      echo "Unsupported gitleaks platform: ${os_name}-${arch_name}" >&2
      exit 1
      ;;
  esac

  archive_path="${TOOLS_DIR}/${asset_name}"
  extract_dir="${TOOLS_DIR}/gitleaks-${version}-${os_name}-${arch_name}"
  binary_path="${extract_dir}/gitleaks"

  if [[ ! -x "${binary_path}" ]]; then
    download_file \
      "https://github.com/gitleaks/gitleaks/releases/download/v${version}/${asset_name}" \
      "${archive_path}"
    extract_tar_archive "${archive_path}" "${extract_dir}"
    chmod +x "${binary_path}"
  fi

  printf "%s" "${binary_path}"
}

ensure_dotenv_linter() {
  local os_name
  local arch_name
  local asset_name
  local extract_dir
  local archive_path
  local version="v4.0.0"
  local binary_path

  os_name="$(normalize_os)"
  arch_name="$(normalize_arch)"

  case "${os_name}-${arch_name}" in
    linux-x86_64)
      asset_name="dotenv-linter-linux-x86_64.tar.gz"
      ;;
    linux-arm64)
      asset_name="dotenv-linter-linux-aarch64.tar.gz"
      ;;
    darwin-x86_64)
      asset_name="dotenv-linter-darwin-x86_64.tar.gz"
      ;;
    darwin-arm64)
      asset_name="dotenv-linter-darwin-arm64.tar.gz"
      ;;
    *)
      echo "Unsupported dotenv-linter platform: ${os_name}-${arch_name}" >&2
      exit 1
      ;;
  esac

  extract_dir="${TOOLS_DIR}/dotenv-linter-${version}-${os_name}-${arch_name}"
  binary_path="$(find "${extract_dir}" -type f -name "dotenv-linter" 2> /dev/null | head -n 1 || true)"

  if [[ -z "${binary_path}" || ! -x "${binary_path}" ]]; then
    archive_path="${TOOLS_DIR}/${asset_name}"
    rm -rf "${extract_dir}"
    mkdir -p "${extract_dir}"
    download_file \
      "https://github.com/dotenv-linter/dotenv-linter/releases/download/${version}/${asset_name}" \
      "${archive_path}"
    tar -xzf "${archive_path}" -C "${extract_dir}"
    binary_path="$(find "${extract_dir}" -type f -name "dotenv-linter" | head -n 1)"
    chmod +x "${binary_path}"
  fi

  printf "%s" "${binary_path}"
}

run_lychee() {
  local image_tag="0.23.0"

  if ! command -v docker > /dev/null 2>&1; then
    echo "lychee requires docker on this project wrapper." >&2
    exit 1
  fi

  exec docker run --rm \
    -v "${ROOT_DIR}:/repo" \
    -w /repo \
    -e "GITHUB_TOKEN=${GITHUB_TOKEN:-}" \
    "lycheeverse/lychee:${image_tag}" \
    "$@"
}

ensure_trivy() {
  local os_name
  local arch_name
  local asset_name
  local version="0.69.3"
  local archive_path
  local extract_dir
  local binary_path

  os_name="$(normalize_os)"
  arch_name="$(normalize_arch)"

  case "${os_name}-${arch_name}" in
    linux-x86_64)
      asset_name="trivy_${version}_Linux-64bit.tar.gz"
      ;;
    linux-arm64)
      asset_name="trivy_${version}_Linux-ARM64.tar.gz"
      ;;
    darwin-x86_64)
      asset_name="trivy_${version}_macOS-64bit.tar.gz"
      ;;
    darwin-arm64)
      asset_name="trivy_${version}_macOS-ARM64.tar.gz"
      ;;
    *)
      echo "Unsupported trivy platform: ${os_name}-${arch_name}" >&2
      exit 1
      ;;
  esac

  archive_path="${TOOLS_DIR}/${asset_name}"
  extract_dir="${TOOLS_DIR}/trivy-${version}-${os_name}-${arch_name}"
  binary_path="${extract_dir}/trivy"

  if [[ ! -x "${binary_path}" ]]; then
    download_file \
      "https://github.com/aquasecurity/trivy/releases/download/v${version}/${asset_name}" \
      "${archive_path}"
    extract_tar_archive "${archive_path}" "${extract_dir}"
    chmod +x "${binary_path}"
  fi

  printf "%s" "${binary_path}"
}

case "${TOOL_NAME}" in
  gitleaks)
    exec "$(ensure_gitleaks)" "$@"
    ;;
  hadolint)
    exec "$(ensure_hadolint)" "$@"
    ;;
  dotenv-linter)
    exec "$(ensure_dotenv_linter)" "$@"
    ;;
  lychee)
    run_lychee "$@"
    ;;
  trivy)
    exec "$(ensure_trivy)" "$@"
    ;;
  *)
    echo "Unsupported quality tool: ${TOOL_NAME}" >&2
    exit 1
    ;;
esac
