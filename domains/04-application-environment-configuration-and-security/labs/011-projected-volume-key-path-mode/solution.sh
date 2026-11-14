#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-011
kubectl -n "$NS" patch deployment billing-gateway --type=json -p='[{"op":"replace","path":"/spec/template/spec/volumes/0/projected/sources/0/configMap/items/0/key","value":"app.yaml"},{"op":"add","path":"/spec/template/spec/volumes/0/projected/defaultMode","value":288}]'
kubectl -n "$NS" rollout status deployment/billing-gateway --timeout=120s
