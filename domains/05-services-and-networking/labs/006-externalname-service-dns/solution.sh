#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-006
kubectl -n "$NS" patch service legacy-payments --type=merge -p '{"spec":{"externalName":"payments-api.ckad-d5-006.svc.cluster.local"}}'
echo "Alias repaired. Run ./verify.sh to check DNS and HTTP."
