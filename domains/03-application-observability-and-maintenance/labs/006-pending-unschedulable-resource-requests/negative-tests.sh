#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NS=ckad-d3-006
restore(){ kubectl apply -f solution.yaml >/dev/null; kubectl -n "$NS" rollout status deploy/orders-api --timeout=180s >/dev/null; }
trap restore EXIT
expect_fail(){ if bash verify.sh >/dev/null 2>&1; then echo "UNEXPECTED PASS: $1"; exit 1; else echo "EXPECTED FAIL: $1"; fi; }
restore
kubectl -n "$NS" set resources deploy/orders-api --requests=cpu=100,memory=32Mi --limits=cpu=200m,memory=128Mi >/dev/null
expect_fail "incorrect CPU request"
restore
kubectl -n "$NS" scale deploy/orders-api --replicas=0 >/dev/null
expect_fail "no ready pods"
restore
kubectl -n "$NS" patch service orders-api -p '{"spec":{"selector":{"app":"missing"}}}' >/dev/null
expect_fail "broken Service selector"
kubectl -n "$NS" patch service orders-api -p '{"spec":{"selector":{"app":"orders-api"}}}' >/dev/null
restore
echo "All negative cases rejected"
