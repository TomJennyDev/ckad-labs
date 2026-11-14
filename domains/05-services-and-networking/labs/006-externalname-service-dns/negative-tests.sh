#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NS=ckad-d5-006
original=$(kubectl -n "$NS" get svc legacy-payments -o jsonpath='{.spec.externalName}')
restore(){ kubectl -n "$NS" patch svc legacy-payments --type=merge -p "{\"spec\":{\"externalName\":\"$original\"}}" >/dev/null; }
trap restore EXIT
./verify.sh || { echo "Baseline must PASS before negative test" >&2; exit 1; }
kubectl -n "$NS" patch svc legacy-payments --type=merge -p '{"spec":{"externalName":"missing.ckad-d5-006.svc.cluster.local"}}' >/dev/null
if ./verify.sh; then echo "FAIL: grader accepted broken alias" >&2; exit 1; fi
echo "PASS: grader rejected broken alias; original value restored on exit"
