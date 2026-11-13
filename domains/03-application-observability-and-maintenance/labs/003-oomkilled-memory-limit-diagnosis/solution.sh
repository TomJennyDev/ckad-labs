#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[[ "$(kubectl config current-context)" == kind-* ]] || { echo "Refusing non-kind context"; exit 2; }
kubectl apply -f setup.yaml
kubectl apply -f solution.yaml
kubectl -n ckad-d3-003 rollout status deploy/report-api --timeout=180s
bash verify.sh
