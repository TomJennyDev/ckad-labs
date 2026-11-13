#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f setup.yaml
kubectl apply -f solution.yaml
kubectl -n ckad-d2-011 rollout status daemonset/node-agent --timeout=180s
./verify.sh
