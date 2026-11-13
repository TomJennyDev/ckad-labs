#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NS=ckad-d3-007
restore() { kubectl apply -f solution.yaml >/dev/null; kubectl -n "$NS" rollout restart deployment/checkout-client >/dev/null; }
trap restore EXIT
expect_fail() {
  local label="$1"
  if ./verify.sh >/dev/null 2>&1; then echo "FAIL negative test: $label"; exit 1; fi
  echo "PASS negative test: $label"
}
kubectl -n "$NS" patch configmap client-config --type merge -p '{"data":{"BACKEND_HOST":"inventory-wrong"}}' >/dev/null
expect_fail "wrong DNS host"
restore
kubectl -n "$NS" patch configmap client-config --type merge -p '{"data":{"BACKEND_HOST":"inventory.other-namespace.svc.cluster.local"}}' >/dev/null
expect_fail "wrong namespace"
restore
kubectl -n "$NS" patch service inventory --type merge -p '{"spec":{"selector":{"app":"missing"}}}' >/dev/null
expect_fail "service without endpoints"
kubectl -n "$NS" patch service inventory --type merge -p '{"spec":{"selector":{"app":"inventory"}}}' >/dev/null
restore
echo "All three negative assertions passed"
