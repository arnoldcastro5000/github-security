#!/usr/bin/env bash
# Write one findings table per SARIF report to the job summary (stdout outside CI).
# Reports from the secrets scanners are --redact, so the table holds no secret value.
# Usage: sarif-summary.sh <title> <dir with *.sarif>
set -euo pipefail

title="$1"
dir="$2"
target="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

{
  echo "## ${title}"
  shopt -s nullglob
  reports=("$dir"/*.sarif)
  if [ "${#reports[@]}" -eq 0 ]; then
    echo "No SARIF report. The tools of this check do not write SARIF, or the scan did not finish; see the step log."
  fi
  for report in "${reports[@]}"; do
    tool="$(basename "$report" .sarif)"
    count="$(jq '[.runs[].results[]?] | length' "$report")"
    echo "### ${tool}"
    if [ "$count" -eq 0 ]; then
      echo "No findings."
    else
      echo "**${count} finding(s).** Fix the cause. To suppress a false positive, see docs/controls.md (Suppression)."
      echo
      echo "| Rule | Level | Location | Line |"
      echo "|---|---|---|---|"
      jq -r '.runs[].results[]?
        | (.locations[0].physicalLocation // {}) as $loc
        | "| \(.ruleId // "n/a") | \(.level // "warning") | \($loc.artifactLocation.uri // "n/a") | \($loc.region.startLine // "") |"' \
        "$report" | head -200
      if [ "$count" -gt 200 ]; then
        echo
        echo "Only the first 200 findings are shown."
      fi
    fi
    echo
  done
} >> "$target"
