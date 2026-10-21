#!/usr/bin/env bash
# Node module: lockfile-lint (registry hosts, HTTPS, integrity), npm ci --ignore-scripts
# (lockfile matches package.json; no install scripts run), npm audit (high and critical),
# semgrep (JavaScript, TypeScript, React, and the shared rules in config/semgrep).
# Usage: node.sh <path>   (the directory with package.json and package-lock.json)
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cd "${1:-.}"

if [ ! -f package-lock.json ]; then
  echo "node.sh: no package-lock.json in $PWD. The Node module needs a committed npm lockfile." >&2
  exit 2
fi

check lockfile-lint npx --yes "lockfile-lint@${LOCKFILE_LINT_VERSION:?load pins.env first}" \
  --path package-lock.json --type npm --validate-https --allowed-hosts npm --validate-integrity
check npm-ci npm ci --ignore-scripts --no-audit --no-fund
check npm-audit npm audit --audit-level=high
check semgrep semgrep scan --metrics=off --quiet --error \
  --config p/javascript --config p/typescript --config p/react \
  --config "$BASELINE_ROOT/config/semgrep" \
  --exclude node_modules \
  --sarif-output="$BASELINE_OUT/semgrep.sarif" .

scan_exit
