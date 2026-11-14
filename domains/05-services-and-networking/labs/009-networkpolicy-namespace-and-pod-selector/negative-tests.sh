#!/usr/bin/env bash
set -euo pipefail
dir=$(cd "$(dirname "$0")" && pwd)
restore(){ bash "$dir/solution.sh" >/dev/null || echo "WARNING: failed to restore solution" >&2; }
trap restore EXIT
# Regression: split the AND peer into two OR peers. Grader must reject this.
kubectl -n ckad-d5-009-api patch networkpolicy billing-ingress --type=json -p='[
 {"op":"replace","path":"/spec/ingress/0/from","value":[
   {"namespaceSelector":{"matchLabels":{"access-tier":"trusted"}}},
   {"podSelector":{"matchLabels":{"role":"billing-client"}}}
 ]}
]' >/dev/null
if bash "$dir/verify.sh"; then
  echo "FAIL: grader accepted OR instead of AND" >&2
  exit 1
fi
echo "PASS: negative test rejected OR mutation; solution restored by EXIT trap"
