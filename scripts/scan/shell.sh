#!/usr/bin/env bash
# Shell module: shellcheck on every shell script. A shell script is a *.sh or *.bash file, or
# a file without an extension whose first line is a sh or bash shebang (for example git hooks).
# Usage: shell.sh <path>
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cd "${1:-.}"

scripts=()
while IFS= read -r -d '' file; do
  case "${file##*/}" in
    *.sh | *.bash) scripts+=("$file") ;;
    *.*) ;;
    *) if head -n1 "$file" | grep -qE '^#!.*\b(ba)?sh\b'; then scripts+=("$file"); fi ;;
  esac
done < <(find . -type f -not -path './.git/*' -not -path '*/node_modules/*' -print0)

if [ "${#scripts[@]}" -eq 0 ]; then
  skip shellcheck "no shell scripts"
else
  printf 'shellcheck: %s\n' "${scripts[@]}"
  check shellcheck shellcheck --external-sources "${scripts[@]}"
fi

scan_exit
