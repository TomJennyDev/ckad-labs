#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-003
if kubectl -n "$NS" get pod storefront -o jsonpath='{.spec.containers[0].env[0].value}' 2>/dev/null | grep -qx 'http://catalog.ckad-d5-003-backend.svc.cluster.local:80/'; then exit 0; fi
kubectl -n "$NS" delete pod storefront --ignore-not-found --wait=true
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: storefront, namespace: ckad-d5-003}
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "sleep 86400"]
    env: [{name: CATALOG_URL, value: "http://catalog.ckad-d5-003-backend.svc.cluster.local:80/"}]
YAML
