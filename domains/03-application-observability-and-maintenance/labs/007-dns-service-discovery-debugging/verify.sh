#!/usr/bin/env bash
set -uo pipefail
NS=ckad-d3-007
score=0
total=8
check() { if "$@" >/dev/null 2>&1; then score=$((score+1)); echo "PASS $score: $*"; else echo "FAIL: $*"; fi; }
command -v kubectl >/dev/null || { echo "kubectl missing"; exit 2; }
kubectl cluster-info >/dev/null 2>&1 || { echo "Kubernetes unreachable"; exit 2; }
check kubectl get namespace "$NS"
check kubectl -n "$NS" get service inventory
check kubectl -n "$NS" rollout status deployment/inventory --timeout=30s
check kubectl -n "$NS" rollout status deployment/checkout-client --timeout=30s
endpoints=$(kubectl -n "$NS" get endpointslice -l kubernetes.io/service-name=inventory -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null || true)
if [ -n "$endpoints" ]; then score=$((score+1)); echo "PASS: backend EndpointSlice populated"; else echo "FAIL: no backend endpoints"; fi
host=$(kubectl -n "$NS" get configmap client-config -o jsonpath='{.data.BACKEND_HOST}' 2>/dev/null || true)
if [ "$host" = "inventory.ckad-d3-007.svc.cluster.local" ]; then score=$((score+1)); echo "PASS: correct FQDN"; else echo "FAIL: wrong BACKEND_HOST=$host"; fi
pod=$(kubectl -n "$NS" get pods -l app=checkout-client -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$pod" ] && kubectl -n "$NS" exec "$pod" -- nslookup inventory.ckad-d3-007.svc.cluster.local >/dev/null 2>&1; then score=$((score+1)); echo "PASS: in-pod DNS"; else echo "FAIL: in-pod DNS"; fi
if [ -n "$pod" ] && kubectl -n "$NS" exec "$pod" -- wget -q -T 5 -O /dev/null http://inventory.ckad-d3-007.svc.cluster.local/ >/dev/null 2>&1; then score=$((score+1)); echo "PASS: in-pod HTTP"; else echo "FAIL: in-pod HTTP"; fi
echo "SCORE $score/$total"
[ "$score" -eq "$total" ]
