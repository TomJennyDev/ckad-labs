#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NS=ckad-d3-002
kubectl config current-context | grep -q '^kind-' || exit 2
restore(){ kubectl apply -f solution.yaml >/dev/null; kubectl -n "$NS" rollout status deploy/payment-worker --timeout=180s >/dev/null; }
trap restore EXIT
restore
expect_fail(){
  local name="$1"
  if bash verify.sh >/dev/null 2>&1; then echo "FAIL negative: $name"; exit 1; fi
  echo "PASS negative: $name"
}
kubectl -n "$NS" scale deploy/payment-worker --replicas=2 >/dev/null
expect_fail "wrong replica count"
restore
kubectl -n "$NS" set image deploy/payment-worker log-streamer=busybox:1.35 >/dev/null
# Image drift alone is not graded; intentionally break sidecar command instead
kubectl -n "$NS" patch deploy payment-worker --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/1/command","value":["/bin/sh","-c"]},{"op":"replace","path":"/spec/template/spec/containers/1/args","value":["sleep 3600"]}]' >/dev/null
kubectl -n "$NS" rollout status deploy/payment-worker --timeout=180s >/dev/null
expect_fail "sidecar produces no logs"
restore
kubectl -n "$NS" patch deploy payment-worker --type=json -p='[{"op":"remove","path":"/spec/template/spec/containers/1/volumeMounts"}]' >/dev/null
expect_fail "missing sidecar mount"
restore
kubectl -n "$NS" patch deploy payment-worker --type=json -p='[{"op":"remove","path":"/spec/template/spec/containers/1"}]' >/dev/null
expect_fail "missing sidecar"
restore
echo "All negative cases rejected"
