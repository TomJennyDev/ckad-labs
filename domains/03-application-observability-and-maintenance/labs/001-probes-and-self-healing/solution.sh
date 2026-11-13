#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[[ "$(kubectl config current-context)" == kind-* ]] || { echo "Require kind context" >&2; exit 1; }
kubectl apply -f solution.yaml
kubectl -n ckad-d3-001 rollout status deployment/checkout-api --timeout=180s
./verify.sh
