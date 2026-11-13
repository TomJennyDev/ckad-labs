#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f setup.yaml
kubectl apply -f solution.yaml
kubectl -n ckad-d2-012 delete job manual-reconcile --ignore-not-found --wait=true
kubectl -n ckad-d2-012 create job manual-reconcile --from=cronjob/billing-reconcile
kubectl -n ckad-d2-012 label job manual-reconcile ckad-lab=d2-012-manual --overwrite
kubectl -n ckad-d2-012 wait --for=condition=complete job/manual-reconcile --timeout=120s
./verify.sh
