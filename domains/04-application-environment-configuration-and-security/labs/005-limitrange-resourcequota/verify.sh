#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-005
fail(){ echo "FAIL: $*" >&2; exit 1; }
pass(){ echo "PASS: $*"; }
kubectl get namespace "$NS" >/dev/null || fail "namespace absent"
kubectl -n "$NS" get limitrange workload-defaults >/dev/null || fail "LimitRange absent"
kubectl -n "$NS" get resourcequota team-budget >/dev/null || fail "ResourceQuota absent"
[ "$(kubectl -n "$NS" get deployment report-api -o jsonpath='{.spec.replicas}')" = "2" ] || fail "replicas != 2"
req=$(kubectl -n "$NS" get deploy report-api -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
lim=$(kubectl -n "$NS" get deploy report-api -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
[ "$req" = "100m" ] && [ "$lim" = "250m" ] || fail "incorrect CPU request/limit: $req/$lim"
kubectl -n "$NS" rollout status deploy/report-api --timeout=120s >/dev/null || fail "rollout not healthy"
ready=$(kubectl -n "$NS" get deployment report-api -o jsonpath='{.status.readyReplicas}')
[ "$ready" = "2" ] || fail "readyReplicas=$ready"
pods=$(kubectl -n "$NS" get pods -l app=report-api -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
[ "$(printf '%s\n' "$pods" | grep -c .)" = "2" ] || fail "pod count != 2"
for pod in $pods; do
  [ "$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.spec.containers[0].resources.requests.cpu}')" = "100m" ] || fail "wrong pod request"
done
kubectl -n "$NS" get endpointslice -l kubernetes.io/service-name=report-api -o name | grep -q . || fail "no EndpointSlice"
# Admission negative check: rejected oversized Pod must not be created.
if kubectl -n "$NS" run quota-probe --image=nginx:1.27-alpine --restart=Never --requests='cpu=500m,memory=64Mi' --limits='cpu=600m,memory=128Mi' >/dev/null 2>&1; then
  kubectl -n "$NS" delete pod quota-probe --ignore-not-found --wait=false >/dev/null
  fail "oversized pod unexpectedly admitted"
fi
pass "2 Ready pods, correct resources, Service endpoints and quota admission rejection"
