#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-007
kubectl -n "$NS" patch deployment identity-api --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"POD_NAME","value":null,"valueFrom":{"fieldRef":{"fieldPath":"metadata.name"}}},{"name":"POD_NAMESPACE","value":null,"valueFrom":{"fieldRef":{"fieldPath":"metadata.namespace"}}},{"name":"NODE_NAME","value":null,"valueFrom":{"fieldRef":{"fieldPath":"spec.nodeName"}}},{"name":"CPU_REQUEST","value":null,"valueFrom":{"resourceFieldRef":{"containerName":"api","resource":"requests.cpu","divisor":"1m"}}}]}]}}}}'
kubectl -n "$NS" rollout status deployment/identity-api --timeout=180s
bash "$(dirname "$0")/verify.sh"
