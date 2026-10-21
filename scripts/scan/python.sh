#!/usr/bin/env bash
# Python module: ruff (lint), semgrep p/python (SAST), pip-audit (known vulnerable packages).
# pip-audit audits each hash-pinned requirements*.lock first (the full transitive set, with
# --no-deps), then each requirements*.txt that has no sibling lockfile (resolves its deps).
# Usage: python.sh <path>
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cd "${1:-.}"

check ruff ruff check --output-format full .
ruff check --output-format sarif --exit-zero . > "$BASELINE_OUT/ruff.sarif"

check semgrep semgrep scan --metrics=off --quiet --error \
  --config p/python --sarif-output="$BASELINE_OUT/semgrep.sarif" .

# shellcheck disable=SC2329 # check() calls this function
pip_audit_all() {
  local status=0 found=0 file
  while IFS= read -r -d '' file; do
    found=1
    echo "pip-audit (lock) $file"
    pip-audit --no-deps --disable-pip -r "$file" || status=1
  done < <(find . -name 'requirements*.lock' -not -path '*/.venv/*' -not -path '*/node_modules/*' -print0)
  while IFS= read -r -d '' file; do
    [ -f "${file%.txt}.lock" ] && continue
    found=1
    echo "pip-audit (requirements) $file"
    pip-audit -r "$file" || status=1
  done < <(find . -name 'requirements*.txt' -not -path '*/.venv/*' -not -path '*/node_modules/*' -print0)
  if [ "$found" -eq 0 ]; then
    echo "No requirements*.txt or requirements*.lock file."
  fi
  return "$status"
}
check pip-audit pip_audit_all

scan_exit
