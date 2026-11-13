#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-006
fail(){ echo "FAIL: $*" >&2; exit 1; }
pass(){ echo "PASS: $*"; }
kubectl get ns "$NS" >/dev/null 2>&1 || fail "namespace absent"
kubectl -n "$NS" get deploy orders-api >/dev/null 2>&1 || fail "deployment absent"
replicas=$(kubectl -n "$NS" get deploy orders-api -o jsonpath='{.status.readyReplicas}')
[[ "$replicas" == "1" ]] || fail "expected 1 ready replica, got ${replicas:-0}"
reqcpu=$(kubectl -n "$NS" get deploy orders-api -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
reqmem=$(kubectl -n "$NS" get deploy orders-api -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
limmem=$(kubectl -n "$NS" get deploy orders-api -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
[[ "$reqcpu" == "50m" && "$reqmem" == "32Mi" && "$limmem" == "128Mi" ]] || fail "resource budget mismatch: $reqcpu/$reqmem/$limmem"
pod=$(kubectl -n "$NS" get pods -l app=orders-api -o jsonpath='{.items[0].metadata.name}')
[[ -n "$pod" ]] || fail "no selected pod"
phase=$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.status.phase}')
node=$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.spec.nodeName}')
[[ "$phase" == Running && -n "$node" ]] || fail "pod not scheduled and running"
svc=$(kubectl -n "$NS" get service orders-api -o jsonpath='{.spec.selector.app}')
[[ "$svc" == "orders-api" ]] || fail "service selector mismatch"
eps=$(kubectl -n "$NS" get endpointslice -l kubernetes.io/service-name=orders-api -o jsonpath='{range .items[*].endpoints[*]}{.conditions.ready}{" "}{end}')
[[ " $eps " == *" true "* ]] || fail "no ready EndpointSlice endpoint"
kubectl -n "$NS" run "probe-$(date +%s)" --rm -i --restart=Never --image=busybox:1.36 --command -- wget -q -O /dev/null -T 8 http://orders-api >/dev/null || fail "HTTP service check failed"
pass "deployment, scheduler placement, resource requests, EndpointSlice and HTTP"
