#!/usr/bin/env bash
# Shared helpers for the scan scripts. Source this file; do not run it.
#
# Each scan script runs every check of one concern, even after a check fails, and exits 1
# when any check fails. Each check prints one result line, "<label>: pass" or "<label>: FAIL",
# which tests/selftest.sh reads. SARIF reports go to $BASELINE_OUT.

baseline_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export BASELINE_ROOT="$baseline_root"

if [ -z "${BASELINE_OUT:-}" ]; then
  if [ -n "${RUNNER_TEMP:-}" ]; then
    BASELINE_OUT="$RUNNER_TEMP/baseline-out"
  else
    BASELINE_OUT="$(mktemp -d)"
  fi
fi
export BASELINE_OUT
mkdir -p "$BASELINE_OUT"

scan_status=0

# check <label> <command>...: run one check and record its result.
check() {
  local label="$1"
  shift
  echo "::group::${label}"
  if "$@"; then
    echo "::endgroup::"
    echo "${label}: pass"
  else
    echo "::endgroup::"
    echo "${label}: FAIL"
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
      echo "::error title=${label}::${label} found issues. See the step log and the job summary."
    fi
    scan_status=1
  fi
}

# skip <label> <reason>: record a check that does not apply to this repo.
skip() {
  echo "${1}: skip (${2})"
}

scan_exit() {
  exit "$scan_status"
}
