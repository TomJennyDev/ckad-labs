#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[[ "$(kubectl config current-context)" == kind-* ]] || exit 1
./solution.sh >/dev/null
restore(){ kubectl apply -f solution.yaml >/dev/null; kubectl -n ckad-d3-001 rollout status deploy/checkout-api --timeout=180s >/dev/null; }
trap restore EXIT
for kind in readinessProbe livenessProbe startupProbe; do
  kubectl -n ckad-d3-001 patch deploy checkout-api --type=json -p "[{\"op\":\"remove\",\"path\":\"/spec/template/spec/containers/0/$kind\"}]" >/dev/null
  if ./verify.sh >/dev/null 2>&1; then echo "FAIL: grader accepted missing $kind"; exit 1; fi
  echo "PASS negative: missing $kind"
  restore
done
kubectl -n ckad-d3-001 scale deploy/checkout-api --replicas=1 >/dev/null
if ./verify.sh >/dev/null 2>&1; then echo "FAIL: grader accepted one replica"; exit 1; fi
echo "PASS negative: one replica"
restore
kubectl -n ckad-d3-001 patch svc checkout-api -p '{"spec":{"selector":{"app":"other"}}}' >/dev/null
if ./verify.sh >/dev/null 2>&1; then echo "FAIL: grader accepted wrong selector"; exit 1; fi
echo "PASS negative: wrong selector"
restore
./verify.sh
