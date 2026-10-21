#!/usr/bin/env bash
# OPA module: regal (Rego lint) and conftest verify (the policy unit tests).
# Usage: opa.sh <path> [policy-dir]   (policy-dir is relative to path; default "policy")
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cd "${1:-.}"
policy_dir="${2:-policy}"

# shellcheck disable=SC2329 # check() calls this function
regal_lint() {
  local rc=0
  regal lint . || rc=$?
  regal lint --format sarif . > "$BASELINE_OUT/regal.sarif" || true
  return "$rc"
}
check regal regal_lint

if [ -d "$policy_dir" ]; then
  check conftest conftest verify --policy "$policy_dir"
else
  echo "opa.sh: policy directory '$policy_dir' not found in $PWD" >&2
  check conftest false
fi

scan_exit
