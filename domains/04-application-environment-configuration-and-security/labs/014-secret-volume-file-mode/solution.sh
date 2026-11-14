#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-014
kubectl -n "$NS" get deployment gateway >/dev/null
kubectl -n "$NS" patch deployment gateway --type=json -p='[{"op":"add","path":"/spec/template/spec/securityContext/fsGroup","value":10001},{"op":"replace","path":"/spec/template/spec/volumes/0/secret/defaultMode","value":288}]'
kubectl -n "$NS" rollout status deployment/gateway --timeout=180s
