#!/usr/bin/env bash
# Workflow security: zizmor (security audit of workflows and actions) and actionlint
# (workflow syntax, expressions, and shellcheck on run: blocks when shellcheck is on PATH).
# zizmor runs its online audits when GH_TOKEN is set.
# Usage: workflow-security.sh <path>
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cd "${1:-.}"

# shellcheck disable=SC2329 # check() calls this function
zizmor_scan() {
  # One run for the log and the exit code, one for the SARIF report.
  local rc=0
  zizmor . || rc=$?
  zizmor --format sarif --no-exit-codes . > "$BASELINE_OUT/zizmor.sarif"
  return "$rc"
}

workflows=()
if [ -d .github/workflows ]; then
  while IFS= read -r -d '' file; do
    workflows+=("$file")
  done < <(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) -print0)
fi

if [ "${#workflows[@]}" -eq 0 ] && [ -z "$(find . -name action.yml -o -name action.yaml | head -1)" ]; then
  skip zizmor "no workflows or actions"
else
  check zizmor zizmor_scan
fi

if [ "${#workflows[@]}" -eq 0 ]; then
  skip actionlint "no workflows"
else
  check actionlint actionlint "${workflows[@]}"
fi

scan_exit
