#!/usr/bin/env bash
set -euo pipefail
dir=$(cd "$(dirname "$0")" && pwd)
n=ckad-d5-008
restore(){ bash "$dir/solution.sh" >/dev/null; }
trap restore EXIT
# Remove DNS allow while retaining pricing-api egress; grader must reject this mutation.
kubectl -n "$n" patch networkpolicy checkout-egress --type=json -p='[{"op":"remove","path":"/spec/egress/0"}]' >/dev/null
if bash "$dir/verify.sh"; then
  echo "FAIL: grader accepted missing DNS egress" >&2
  exit 1
fi
echo "PASS: negative mutation rejected; solution restored on exit"
