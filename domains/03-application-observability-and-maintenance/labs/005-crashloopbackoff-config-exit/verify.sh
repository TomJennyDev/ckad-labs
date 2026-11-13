#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-005
fail(){ echo "FAIL: $*" >&2; exit 1; }
pass(){ echo "PASS: $*"; }
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "namespace missing"
kubectl -n "$NS" get deploy invoice-worker >/dev/null 2>&1 || fail "Deployment missing"
MODE=$(kubectl -n "$NS" get cm invoice-worker-config -o jsonpath='{.data.WORKER_MODE}') || fail "ConfigMap missing"
[[ "$MODE" == consume ]] || fail "WORKER_MODE is not consume"
pass "ConfigMap correct"
REPLICAS=$(kubectl -n "$NS" get deploy invoice-worker -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == 2 ]] || fail "replicas must equal 2"
IMAGE=$(kubectl -n "$NS" get deploy invoice-worker -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMAGE" == busybox:1.36 ]] || fail "image changed"
CMD=$(kubectl -n "$NS" get deploy invoice-worker -o jsonpath='{.spec.template.spec.containers[0].args[0]}')
[[ "$CMD" == *'WORKER_MODE'* && "$CMD" == *'exit 42'* && "$CMD" == *'worker-ready'* ]] || fail "validation command removed"
REF=$(kubectl -n "$NS" get deploy invoice-worker -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.configMapKeyRef.name}')
KEY=$(kubectl -n "$NS" get deploy invoice-worker -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.configMapKeyRef.key}')
[[ "$REF" == invoice-worker-config && "$KEY" == WORKER_MODE ]] || fail "ConfigMap env reference wrong"
pass "Deployment specification"
kubectl -n "$NS" rollout status deploy/invoice-worker --timeout=120s >/dev/null || fail "rollout failed"
READY=$(kubectl -n "$NS" get deploy invoice-worker -o jsonpath='{.status.readyReplicas}')
[[ "$READY" == 2 ]] || fail "ready replicas != 2"
PODS=$(kubectl -n "$NS" get pods -l app=invoice-worker -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{" "}{end}')
COUNT=0
for pod in $PODS; do
  IS_READY=$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}')
  [[ "$IS_READY" == true ]] || continue
  LOG=$(kubectl -n "$NS" logs "$pod" -c worker --tail=20) || fail "logs unavailable for $pod"
  [[ "$LOG" == *worker-ready* ]] || fail "worker-ready missing from $pod logs"
  COUNT=$((COUNT+1))
done
[[ "$COUNT" == 2 ]] || fail "expected 2 running ready Pods with worker-ready logs, got $COUNT"
pass "2 Ready Pods and real application logs"
echo "PASS D3-005"
