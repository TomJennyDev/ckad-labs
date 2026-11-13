#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f solution.yaml
kubectl -n ckad-d3-006 rollout status deployment/orders-api --timeout=180s
