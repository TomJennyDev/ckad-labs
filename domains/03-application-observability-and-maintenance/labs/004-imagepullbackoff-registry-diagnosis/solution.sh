#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f setup.yaml >/dev/null
kubectl apply -f solution.yaml
kubectl -n ckad-d3-004 rollout status deployment/catalog-api --timeout=180s
./verify.sh
