#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-003
HERE="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$HERE/setup.yaml" >/dev/null
kubectl -n "$NS" wait --for=condition=Ready pod/audit-client --timeout=180s
expect_fail() {
  local name="$1"
  if "$HERE/verify.sh" >/dev/null 2>&1; then echo "FAIL negative: $name escaped grader"; exit 1; fi
  echo "PASS negative: $name detected"
}
trap '"$HERE/solution.sh" >/dev/null' EXIT
"$HERE/solution.sh" >/dev/null
"$HERE/verify.sh" >/dev/null
kubectl -n "$NS" patch role auditor-reader --type=json -p='[{"op":"add","path":"/rules/0/resources/-","value":"secrets"}]' >/dev/null
expect_fail "Secret privilege escalation"
"$HERE/solution.sh" >/dev/null
kubectl -n "$NS" patch role auditor-reader --type=json -p='[{"op":"remove","path":"/rules/0/resourceNames"}]' >/dev/null
expect_fail "All ConfigMaps exposed"
"$HERE/solution.sh" >/dev/null
kubectl -n "$NS" patch rolebinding auditor-binding --type=json -p='[{"op":"replace","path":"/subjects/0/name","value":"default"}]' >/dev/null
expect_fail "Wrong bound ServiceAccount"
kubectl -n "$NS" patch rolebinding auditor-binding --type=json -p='[{"op":"replace","path":"/subjects/0/name","value":"auditor"}]' >/dev/null
"$HERE/solution.sh" >/dev/null
echo "All negative tests detected"
