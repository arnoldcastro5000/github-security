#!/usr/bin/env bash
# Secrets: gitleaks and betterleaks (default rules, the repo's .gitleaks.toml, and rule packs),
# then trufflehog for verified live credentials.
# Usage: secrets.sh [--mode git|dir] [--rule-packs "<pack> ..."] <path>
#   --mode git   scan every commit (needs full history; the default)
#   --mode dir   scan the files only (the self-test fixtures have no git history)
# Reports are --redact, so logs and SARIF hold no secret value.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

mode=git
packs=""
while [ $# -gt 1 ]; do
  case "$1" in
    --mode) mode="$2"; shift 2 ;;
    --rule-packs) packs="$2"; shift 2 ;;
    *) echo "secrets.sh: unknown option $1" >&2; exit 2 ;;
  esac
done
cd "${1:-.}"

# The generated config extends the repo's .gitleaks.toml when it has one (that file keeps
# useDefault = true and adds the repo's own rules and allowlists), else the default rules.
config="$BASELINE_OUT/gitleaks.toml"
{
  echo 'title = "baseline"'
  echo
  echo '[extend]'
  if [ -f .gitleaks.toml ]; then
    printf 'path = "%s"\n' "$PWD/.gitleaks.toml"
  else
    echo 'useDefault = true'
  fi
  for pack in $packs; do
    pack_file="$BASELINE_ROOT/config/rule-packs/${pack}.toml"
    if [ ! -f "$pack_file" ]; then
      echo "secrets.sh: unknown rule pack '$pack'" >&2
      exit 2
    fi
    echo
    cat "$pack_file"
  done
} > "$config"

# shellcheck disable=SC2329 # check() calls this function
leaks() {
  local tool="$1"
  "$tool" "$mode" . --config "$config" --redact --no-banner \
    --report-format sarif --report-path "$BASELINE_OUT/${tool}.sarif"
}

check gitleaks leaks gitleaks
check betterleaks leaks betterleaks

if [ "$mode" = git ]; then
  check trufflehog trufflehog git "file://$PWD" --results=verified --fail --no-update
else
  check trufflehog trufflehog filesystem . --results=verified --fail --no-update
fi

scan_exit
