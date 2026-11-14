#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-010
kubectl get namespace "$NS" >/dev/null
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: catalog-config-v2
immutable: true
data:
  CATALOG_VERSION: v2
YAML
kubectl -n "$NS" patch deployment catalog-api --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"CATALOG_VERSION","valueFrom":{"configMapKeyRef":{"name":"catalog-config-v2","key":"CATALOG_VERSION"}}}]}]}}}}'
kubectl -n "$NS" rollout status deployment/catalog-api --timeout=180s
bash "$(dirname "$0")/verify.sh"
