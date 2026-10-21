#!/usr/bin/env bash
# Install pinned tools from pins.env (linux x64).
# A binary tool must match the SHA-256 pinned in pins.env, so a replaced release asset fails
# the install. A Python tool is installed with pipx at its pinned version.
# In CI the binaries go to $RUNNER_TEMP/bin and onto PATH. Locally they go to
# $BASELINE_BIN_DIR (default ~/.local/bin).
# Usage: install-tool.sh <tool>...   (tool names as in pins.env, lower case, for example pip-audit)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091 # pins.env is at the repo root and holds only VAR=value lines
source "$here/../pins.env"

if [ -n "${RUNNER_TEMP:-}" ]; then
  bin="${BASELINE_BIN_DIR:-${RUNNER_TEMP}/bin}"
else
  bin="${BASELINE_BIN_DIR:-${HOME}/.local/bin}"
fi
mkdir -p "$bin"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$bin" >> "$GITHUB_PATH"
fi

workroot="$(mktemp -d)"
trap 'rm -rf "$workroot"' EXIT

install_binary() {
  local tool="$1" url="$2" sha256="$3"
  local work="$workroot/$tool" archive found
  mkdir -p "$work"
  archive="$work/$(basename "$url")"
  curl -fsSL --retry 3 -o "$archive" "$url"
  echo "${sha256}  ${archive}" | sha256sum -c --quiet -
  case "$archive" in
    *.tar.gz | *.tgz) tar -xzf "$archive" -C "$work" ;;
    *.tar.xz)
      # Some hosts have no xz binary; Python's lzma module reads the archive too.
      if command -v xz >/dev/null; then
        tar -xJf "$archive" -C "$work"
      else
        python3 -c 'import sys, tarfile; tarfile.open(sys.argv[1]).extractall(sys.argv[2], filter="data")' "$archive" "$work"
      fi
      ;;
    *.zip) unzip -q "$archive" -d "$work" ;;
    *) cp "$archive" "$work/$tool" ;;
  esac
  found="$(find "$work" -type f -name "$tool" | head -1)"
  if [ -z "$found" ]; then
    echo "install-tool: no '$tool' binary in $(basename "$url")" >&2
    return 1
  fi
  install -m 0755 "$found" "$bin/$tool"
}

for tool in "$@"; do
  key="$(echo "$tool" | tr '[:lower:]-' '[:upper:]_')"
  version_var="${key}_VERSION"
  url_var="${key}_URL"
  sha_var="${key}_SHA256"
  version="${!version_var:-}"
  if [ -z "$version" ]; then
    echo "install-tool: '$tool' is not pinned in pins.env" >&2
    exit 2
  fi
  if [ -n "${!url_var:-}" ]; then
    install_binary "$tool" "${!url_var}" "${!sha_var:?${sha_var} is not set in pins.env}"
  else
    pipx install --quiet --force "${tool}==${version}" >/dev/null
  fi
  echo "installed: $tool $version"
done
