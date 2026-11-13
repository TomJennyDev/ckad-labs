#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-007
DIR="$(cd "$(dirname "$0")" && pwd)"
kubectl -n "$NS" set env deployment/identity-api POD_NAME=hardcoded-pod
kubectl -n "$NS" rollout status deploy/identity-api --timeout=180s
if bash "$DIR/verify.sh"; then echo "FAIL: grader accepted invalid POD_NAME"; exit 1; fi
echo "PASS: grader rejected hardcoded metadata"
bash "$DIR/solution.sh"
kubectl -n "$NS" set env deployment/identity-api CPU_REQUEST=999
kubectl -n "$NS" rollout status deploy/identity-api --timeout=180s
if bash "$DIR/verify.sh"; then echo "FAIL: grader accepted invalid CPU_REQUEST"; exit 1; fi
echo "PASS: grader rejected wrong resourceFieldRef"
bash "$DIR/solution.sh"
