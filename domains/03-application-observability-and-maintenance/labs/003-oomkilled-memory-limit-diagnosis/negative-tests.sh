#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[[ "$(kubectl config current-context)" == kind-* ]] || exit 2
NS=ckad-d3-003
restore(){ kubectl apply -f solution.yaml >/dev/null; kubectl -n "$NS" rollout status deploy/report-api --timeout=180s >/dev/null; }
trap restore EXIT
restore
reject(){ if bash verify.sh >/dev/null 2>&1; then echo "FAIL: accepted $1"; exit 1; else echo "PASS: rejected $1"; fi; }
kubectl -n "$NS" scale deploy/report-api --replicas=2 >/dev/null
reject "replicas=2"; restore
kubectl -n "$NS" set resources deploy/report-api -c api --requests=memory=32Mi,cpu=10m --limits=memory=64Mi,cpu=200m >/dev/null
reject "OOM limit 64Mi"; restore
kubectl -n "$NS" set resources deploy/report-api -c api --requests=memory=64Mi,cpu=10m --limits=memory=192Mi,cpu=200m >/dev/null
reject "insufficient memory request"; restore
kubectl -n "$NS" patch deploy report-api --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args","value":["import time; time.sleep(3600)"]}]' >/dev/null
reject "workload not allocating memory"; restore
echo "All negative cases rejected"
