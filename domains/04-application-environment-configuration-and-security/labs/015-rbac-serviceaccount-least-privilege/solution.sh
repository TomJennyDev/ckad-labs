#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-015
kubectl -n "$NS" get role audit-reader >/dev/null
kubectl -n "$NS" patch role audit-reader --type=merge -p '{"rules":[{"apiGroups":[""],"resources":["configmaps"],"verbs":["get","list"]}]}'
kubectl -n "$NS" wait --for=condition=Ready pod/audit-client --timeout=180s
