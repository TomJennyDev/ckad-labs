#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-001
kubectl -n "$NS" get service inventory-api >/dev/null
kubectl -n "$NS" patch service inventory-api --type=merge -p '{"spec":{"selector":{"app":"inventory-api"}}}'
kubectl -n "$NS" rollout status deployment/inventory-api --timeout=180s
echo "Selector repaired; run bash verify.sh"
