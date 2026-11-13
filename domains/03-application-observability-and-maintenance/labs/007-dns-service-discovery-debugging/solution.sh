#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f solution.yaml
kubectl -n ckad-d3-007 rollout restart deployment/checkout-client
kubectl -n ckad-d3-007 rollout status deployment/checkout-client --timeout=120s
./verify.sh
