#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
restore(){ bash "$DIR/solution.sh" >/dev/null || echo "restore failed" >&2; }
trap restore EXIT
restore
kubectl -n ckad-d4-009 patch deploy checkout-api --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"APP_MODE","value":"staging"}]}]}}}}'
kubectl -n ckad-d4-009 rollout status deploy/checkout-api --timeout=180s >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then echo "FAIL: bad APP_MODE accepted"; exit 1; fi
echo "PASS: bad APP_MODE rejected"
restore
kubectl -n ckad-d4-009 patch deploy checkout-api --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","envFrom":[{"configMapRef":{"name":"checkout-overrides"}},{"configMapRef":{"name":"checkout-defaults"}}]}]}}}}'
kubectl -n ckad-d4-009 rollout status deploy/checkout-api --timeout=180s >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then echo "FAIL: bad envFrom order accepted"; exit 1; fi
echo "PASS: bad envFrom order rejected"
