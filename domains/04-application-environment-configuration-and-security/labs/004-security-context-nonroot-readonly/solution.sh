#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-004
kubectl -n "$NS" patch deployment gateway --type=strategic -p '{
  "spec":{"template":{"spec":{
    "securityContext":{"runAsNonRoot":true,"runAsUser":10001,"runAsGroup":10001,"seccompProfile":{"type":"RuntimeDefault"}},
    "containers":[{"name":"app","securityContext":{"allowPrivilegeEscalation":false,"readOnlyRootFilesystem":true,"capabilities":{"drop":["ALL"]}},
      "volumeMounts":[{"name":"tmp","mountPath":"/tmp"}]}],
    "volumes":[{"name":"tmp","emptyDir":{"sizeLimit":"16Mi"}}]
  }}}}'
kubectl -n "$NS" rollout status deployment/gateway --timeout=180s
bash "$(dirname "$0")/verify.sh"
