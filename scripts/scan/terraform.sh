#!/usr/bin/env bash
# Terraform module: terraform fmt and validate (no backend, no credentials), tflint,
# checkov, and trivy config (HIGH and CRITICAL).
# Usage: terraform.sh <path>
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cd "${1:-.}"

check fmt terraform fmt -check -recursive -diff .

# shellcheck disable=SC2329 # check() calls this function
validate_all() {
  local status=0 dir
  while IFS= read -r dir; do
    echo "validate $dir"
    (cd "$dir" && terraform init -backend=false -input=false >/dev/null && terraform validate) || status=1
  done < <(find . -name '*.tf' -not -path '*/.terraform/*' -printf '%h\n' | sort -u)
  return "$status"
}
check validate validate_all

# shellcheck disable=SC2329 # check() calls this function
tflint_scan() {
  local rc=0
  tflint --init
  tflint --recursive || rc=$?
  tflint --recursive --format sarif --force > "$BASELINE_OUT/tflint.sarif"
  return "$rc"
}
check tflint tflint_scan

check checkov checkov --directory . --framework terraform --quiet --compact \
  --output cli --output sarif --output-file-path "console,$BASELINE_OUT/checkov"
# checkov picks the report file name itself; keep it as checkov.sarif.
checkov_report="$(find "$BASELINE_OUT/checkov" -name '*.sarif' 2>/dev/null | head -1)"
if [ -n "$checkov_report" ]; then
  mv "$checkov_report" "$BASELINE_OUT/checkov.sarif"
else
  echo "terraform.sh: checkov wrote no SARIF report; files: $(find "$BASELINE_OUT/checkov" -type f 2>/dev/null | tr '\n' ' ')"
fi
rm -rf "$BASELINE_OUT/checkov"

# shellcheck disable=SC2329 # check() calls this function
trivy_config() {
  local rc=0
  trivy config --quiet --exit-code 1 --severity HIGH,CRITICAL . || rc=$?
  trivy config --quiet --severity HIGH,CRITICAL --format sarif --output "$BASELINE_OUT/trivy-config.sarif" .
  return "$rc"
}
check trivy-config trivy_config

scan_exit
