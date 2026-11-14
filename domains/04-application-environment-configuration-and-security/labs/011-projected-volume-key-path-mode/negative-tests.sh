#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-011
echo "Negative test: wrong ConfigMap key must prevent Ready"
kubectl -n "$NS" patch deployment billing-gateway --type=json -p='[{"op":"replace","path":"/spec/template/spec/volumes/0/projected/sources/0/configMap/items/0/key","value":"missing.yaml"}]'
kubectl -n "$NS" rollout status deployment/billing-gateway --timeout=25s && { echo "FAIL: unexpectedly Ready"; exit 1; } || true
if bash "$(dirname "$0")/verify.sh"; then echo "FAIL: verifier accepted broken deployment"; exit 1; fi
echo "PASS: verifier rejects missing key"
echo "Restore with: bash solution.sh"
