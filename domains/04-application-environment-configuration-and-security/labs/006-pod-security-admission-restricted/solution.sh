#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-006
kubectl get ns "$NS" >/dev/null
kubectl -n "$NS" patch deployment payments-api --type=strategic -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":10001,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"api","securityContext":{"privileged":false,"allowPrivilegeEscalation":false,"readOnlyRootFilesystem":true,"capabilities":{"drop":["ALL"]}}}]}}}}'
kubectl -n "$NS" rollout status deployment/payments-api --timeout=120s
