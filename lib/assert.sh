#!/usr/bin/env bash
set -euo pipefail
fails=0
eq() {
  if [[ "$1" == "$2" ]]; then echo "PASS $3"
  else echo "FAIL $3: got [$1], expected [$2]"; fails=$((fails+1)); fi
}
nonempty() {
  if [[ -n "$1" ]]; then echo "PASS $2"
  else echo "FAIL $2: missing"; fails=$((fails+1)); fi
}
ok() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS $label"
  else echo "FAIL $label"; fails=$((fails+1)); fi
}
finish() {
  if [[ "$fails" -gt 0 ]]; then echo "$fails assertion(s) failed"; exit 1; fi
  echo "All checks passed."
}
