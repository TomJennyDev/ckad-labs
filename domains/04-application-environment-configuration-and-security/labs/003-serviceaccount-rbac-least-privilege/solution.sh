#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-003
kubectl get ns "$NS" >/dev/null
kubectl -n "$NS" patch role auditor-reader --type=merge -p '{"rules":[{"apiGroups":[""],"resources":["configmaps"],"resourceNames":["public-settings"],"verbs":["get"]}]}'
echo "Role narrowed: only get configmap/public-settings; run ./verify.sh"
