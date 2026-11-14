#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-008
DIR="$(cd "$(dirname "$0")" && pwd)"
restore(){ bash "$DIR/solution.sh" >/dev/null || echo "WARNING: manual restore needed" >&2; }
trap restore EXIT
bash "$DIR/solution.sh" >/dev/null
kubectl -n "$NS" patch deploy invoice-reader --type=json -p='[{"op":"replace","path":"/spec/template/spec/volumes/1/projected/sources/0/serviceAccountToken/audience","value":"https://invalid.example"}]'
kubectl -n "$NS" rollout status deploy/invoice-reader --timeout=180s >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then echo "FAIL: wrong audience accepted"; exit 1; fi
echo "PASS: wrong audience rejected"
restore
kubectl -n "$NS" patch deploy invoice-reader --type=json -p='[{"op":"remove","path":"/spec/template/spec/containers/0/volumeMounts/1"}]'
kubectl -n "$NS" rollout status deploy/invoice-reader --timeout=180s >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then echo "FAIL: missing token mount accepted"; exit 1; fi
echo "PASS: missing token mount rejected"
