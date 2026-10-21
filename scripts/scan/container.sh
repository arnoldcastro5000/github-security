#!/usr/bin/env bash
# Container module: build the image (no push), then trivy image (HIGH and CRITICAL, fixable only).
# Usage: container.sh <context> [dockerfile]   (dockerfile path is relative to the context)
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cd "${1:-.}"
dockerfile="${2:-Dockerfile}"
image="baseline-scan:local"

check build docker build --pull --tag "$image" --file "$dockerfile" .

# shellcheck disable=SC2329 # check() calls this function
trivy_image() {
  local rc=0
  trivy image --quiet --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed "$image" || rc=$?
  trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed \
    --format sarif --output "$BASELINE_OUT/trivy-image.sarif" "$image"
  return "$rc"
}
if docker image inspect "$image" >/dev/null 2>&1; then
  check trivy-image trivy_image
else
  check trivy-image false
fi

scan_exit
