#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-002
kubectl -n "$NS" get svc payments >/dev/null
kubectl -n "$NS" patch svc payments --type=json -p='[{"op":"replace","path":"/spec/ports/0/targetPort","value":"http-app"}]'
kubectl -n "$NS" rollout status deployment/payments-api --timeout=180s
echo "TargetPort repaired; run bash verify.sh"
