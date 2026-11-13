#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NS=ckad-d3-004
restore(){ kubectl apply -f solution.yaml >/dev/null; kubectl -n "$NS" rollout status deployment/catalog-api --timeout=180s >/dev/null; }
trap restore EXIT
./solution.sh >/dev/null
expect_fail(){ if ./verify.sh >/dev/null 2>&1; then echo "FAIL: grader accepted $1"; exit 1; else echo "PASS: grader rejected $1"; fi; }
kubectl -n "$NS" set image deployment/catalog-api web=nginx:ckad-intentionally-missing-tag-2026 >/dev/null
expect_fail "invalid tag"
restore
kubectl -n "$NS" patch deployment catalog-api --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Always"}]' >/dev/null
expect_fail "wrong pull policy"
restore
kubectl -n "$NS" scale deployment/catalog-api --replicas=0 >/dev/null
expect_fail "zero replicas"
restore
kubectl -n "$NS" delete service catalog-api >/dev/null
expect_fail "missing Service"
kubectl apply -f setup.yaml >/dev/null
restore
kubectl -n "$NS" patch service catalog-api -p '{"spec":{"selector":{"app":"wrong-app"}}}' >/dev/null
expect_fail "wrong Service selector"
kubectl -n "$NS" patch service catalog-api -p '{"spec":{"selector":{"app":"catalog-api"}}}' >/dev/null
restore
echo "Negative tests: 5/5"
