#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NS=ckad-d3-005
restore(){
  kubectl apply -f setup.yaml >/dev/null
  kubectl apply -f solution.yaml >/dev/null
  kubectl -n "$NS" rollout restart deploy/invoice-worker >/dev/null
  kubectl -n "$NS" rollout status deploy/invoice-worker --timeout=180s >/dev/null
}
trap restore EXIT
./solution.sh >/dev/null
reject(){ if ./verify.sh >/dev/null 2>&1; then echo "FAIL: accepted $1" >&2; exit 1; else echo "PASS: rejected $1"; fi; }
kubectl -n "$NS" patch cm invoice-worker-config -p '{"data":{"WORKER_MODE":"invalid"}}' >/dev/null
reject "bad ConfigMap"
restore
kubectl -n "$NS" scale deploy/invoice-worker --replicas=1 >/dev/null
reject "one replica"
restore
kubectl -n "$NS" patch deploy invoice-worker --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args/0","value":"sleep 999999"}]' >/dev/null
reject "bypassed validation"
restore
kubectl -n "$NS" patch deploy invoice-worker --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/valueFrom/configMapKeyRef/name","value":"missing-config"}]' >/dev/null
reject "missing ConfigMap"
echo "PASS: 4/4 negative tests"
