#!/usr/bin/env bash
set -euo pipefail
dir=$(cd "$(dirname "$0")" && pwd)
restore(){ bash "$dir/solution.sh" >/dev/null || echo "WARNING: manual restore needed" >&2; }
trap restore EXIT
# Regression mutation: wrong backend port must be rejected by grader even if Pods are Ready.
kubectl -n ckad-d5-010 patch service shipping-public --type=merge -p '{"spec":{"ports":[{"name":"http","protocol":"TCP","port":80,"targetPort":8080,"nodePort":30080}]}}' >/dev/null
if bash "$dir/verify.sh"; then
  echo "FAIL: verifier accepted broken targetPort" >&2
  exit 1
fi
echo "PASS: verifier rejected broken targetPort; restoring via EXIT trap"
