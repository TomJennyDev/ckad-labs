#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-004
fail(){ echo "FAIL: $*" >&2; exit 1; }
pass(){ echo "PASS: $*"; }
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "namespace absent"
kubectl -n "$NS" get deployment catalog-api >/dev/null 2>&1 || fail "Deployment absent"
IMAGE=$(kubectl -n "$NS" get deployment catalog-api -o jsonpath='{.spec.template.spec.containers[?(@.name=="web")].image}')
[[ "$IMAGE" == "nginx:1.27-alpine" ]] || fail "unexpected image: $IMAGE"
pass "image pinned to working tag"
POLICY=$(kubectl -n "$NS" get deployment catalog-api -o jsonpath='{.spec.template.spec.containers[?(@.name=="web")].imagePullPolicy}')
[[ "$POLICY" == "IfNotPresent" ]] || fail "imagePullPolicy wrong"
pass "pull policy"
kubectl -n "$NS" rollout status deployment/catalog-api --timeout=120s >/dev/null || fail "rollout not ready"
READY=$(kubectl -n "$NS" get deployment catalog-api -o jsonpath='{.status.readyReplicas}')
[[ "$READY" == "1" ]] || fail "expected one ready replica"
pass "one ready replica"
POD=$(kubectl -n "$NS" get pods -l app=catalog-api -o jsonpath='{.items[0].metadata.name}')
[[ -n "$POD" ]] || fail "no matching pod"
WAIT=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}')
[[ -z "$WAIT" ]] || fail "container still waiting: $WAIT"
pass "container running"
kubectl -n "$NS" get service catalog-api >/dev/null || fail "Service absent"
ENDPOINTS=$(kubectl -n "$NS" get endpointslice -l kubernetes.io/service-name=catalog-api -o jsonpath='{.items[*].endpoints[*].conditions.ready}')
[[ " $ENDPOINTS " == *" true "* ]] || fail "no ready EndpointSlice"
pass "ready EndpointSlice"
kubectl -n "$NS" run "d3-004-http-$$" --rm -i --restart=Never --image=busybox:1.36 --command -- sh -c 'wget -q -O /dev/null http://catalog-api && echo HTTP_OK' | grep -q HTTP_OK || fail "in-cluster HTTP failed"
pass "HTTP from namespace to Service"
echo "RESULT: 7/7 PASS"
