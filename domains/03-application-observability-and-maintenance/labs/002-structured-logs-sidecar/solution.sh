#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
kubectl config current-context | grep -q '^kind-' || { echo 'Refusing non-kind context' >&2; exit 2; }
kubectl apply -f setup.yaml
kubectl apply -f solution.yaml
kubectl -n ckad-d3-002 rollout status deployment/payment-worker --timeout=180s
bash verify.sh
