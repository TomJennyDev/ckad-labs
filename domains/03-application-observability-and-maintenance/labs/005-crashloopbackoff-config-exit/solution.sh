#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f setup.yaml >/dev/null
kubectl apply -f solution.yaml >/dev/null
kubectl -n ckad-d3-005 rollout restart deployment/invoice-worker >/dev/null
kubectl -n ckad-d3-005 rollout status deployment/invoice-worker --timeout=180s
./verify.sh
