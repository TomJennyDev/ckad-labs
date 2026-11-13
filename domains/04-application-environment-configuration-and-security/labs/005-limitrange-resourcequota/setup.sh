#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f setup.yaml
echo "Expected initial failure: quota permits only 300m CPU requests; 2 replicas each request 200m."
kubectl -n ckad-d4-005 get deploy,rs,pods,resourcequota,limitrange
