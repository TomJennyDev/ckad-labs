#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-009
[[ "$(kubectl config current-context)" == kind-ckad-labs ]] || { echo 'ERROR: use kind-ckad-labs'; exit 2; }
kubectl get namespace "$NS" >/dev/null
# Avoid leaking credentials via CLI arguments, shell history, or Git.
# Lab-only dummy token, never a production secret.
printf 'lab-demo-token-not-for-production' | kubectl -n "$NS" create secret generic receipt-credentials --from-file=token=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$NS" rollout status deployment/receipt-api --timeout=180s
bash "$(dirname "$0")/verify.sh"
