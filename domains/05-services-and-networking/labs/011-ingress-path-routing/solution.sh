#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-011
kubectl -n "$NS" patch ingress storefront --type=json -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/name","value":"catalog"},{"op":"replace","path":"/spec/rules/0/http/paths/1/backend/service/name","value":"checkout"}]'
echo "Ingress backend routing corrected"
