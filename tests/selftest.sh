#!/usr/bin/env bash
# Self-test for one scan concern: run scripts/scan/<concern>.sh on the clean and the dirty
# fixture and check the results.
#
# Fixture layout: tests/fixtures/<concern>/
#   clean/         must pass: exit 0 and no FAIL line
#   dirty/         must fail: exit 1, and every check in expect-fail must FAIL
#   expect-fail    the check labels that must FAIL on dirty/ (one per line)
#   expect-rules   optional: "<tool> <rule-id>" lines that must appear in <tool>.sarif on dirty/
#   options        optional: options for the scan script, given before the path
#
# Files under a fixture carry a ".fixture" suffix where a real name would make other tools
# act on this repo (zizmor, CodeQL, Dependabot, the dependency graph). The test copies the
# fixture to a temp dir and removes the suffix there.
# Usage: selftest.sh <concern>
set -euo pipefail

concern="$1"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixtures="$root/tests/fixtures/$concern"
script="$root/scripts/scan/$concern.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

options=()
if [ -f "$fixtures/options" ]; then
  read -r -a options < "$fixtures/options"
fi

failures=0
fail() {
  echo "SELFTEST FAIL ($concern): $1"
  failures=$((failures + 1))
}

prepare() {
  local variant="$1" target="$work/$1" file
  cp -R "$fixtures/$variant" "$target"
  while IFS= read -r -d '' file; do
    mv "$file" "${file%.fixture}"
  done < <(find "$target" -name '*.fixture' -print0)
  echo "$target"
}

run() {
  local variant="$1" dir out rc=0
  dir="$(prepare "$variant")"
  out="$work/out-$variant"
  mkdir -p "$out"
  echo "=== $concern / $variant"
  BASELINE_OUT="$out" "$script" "${options[@]}" "$dir" > "$work/log-$variant" 2>&1 || rc=$?
  grep -E '^[a-z0-9-]+: (pass|FAIL|skip)' "$work/log-$variant" || true
  echo "exit $rc"
  return "$rc"
}

# Clean: every check passes.
if ! run clean; then
  fail "clean fixture did not pass"
  sed 's/^/  | /' "$work/log-clean" | tail -60
fi
if grep -qE '^[a-z0-9-]+: FAIL' "$work/log-clean"; then
  fail "clean fixture has a FAIL line"
fi

# Dirty: the expected checks fail, and the expected rules appear.
if run dirty; then
  fail "dirty fixture passed"
fi
while IFS= read -r label; do
  [ -z "$label" ] && continue
  grep -qx "${label}: FAIL" "$work/log-dirty" || fail "dirty: check '$label' did not FAIL"
done < "$fixtures/expect-fail"
if [ -f "$fixtures/expect-rules" ]; then
  while read -r tool rule; do
    [ -z "$tool" ] && continue
    sarif="$work/out-dirty/$tool.sarif"
    if [ ! -f "$sarif" ]; then
      fail "dirty: no $tool.sarif"
    elif ! jq -e --arg r "$rule" '[.runs[].results[]?.ruleId] | any(. == $r or endswith("/" + $r) or endswith("." + $r))' "$sarif" >/dev/null; then
      fail "dirty: $tool did not report rule '$rule' (found: $(jq -r '[.runs[].results[]?.ruleId] | unique | join(", ")' "$sarif"))"
    fi
  done < "$fixtures/expect-rules"
fi

if [ "$failures" -gt 0 ]; then
  echo "=== $concern: $failures self-test failure(s)"
  exit 1
fi
echo "=== $concern: self-test passed"
