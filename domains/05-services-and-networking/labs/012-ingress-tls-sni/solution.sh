#!/usr/bin/env bash
set -euo pipefail
[[ "$(kubectl config current-context)" == "kind-ckad-d5-012" ]] || { echo "Wrong kube context" >&2; exit 1; }
kubectl -n ckad-d5-012 patch ingress orders-gateway --type=json \
  -p='[{"op":"replace","path":"/spec/tls/0/secretName","value":"orders-tls"}]'
echo "TLS reference corrected; controller will reconcile asynchronously"
