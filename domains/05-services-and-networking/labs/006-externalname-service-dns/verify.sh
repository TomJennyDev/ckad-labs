#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-006
fail(){ echo "FAIL: $*" >&2; exit 1; }
kubectl get ns "$NS" >/dev/null || fail "namespace missing"
kubectl -n "$NS" rollout status deployment/payments-api --timeout=120s >/dev/null || fail "backend not ready"
kubectl -n "$NS" wait --for=condition=Ready pod/checkout-client --timeout=120s >/dev/null || fail "client not ready"
type=$(kubectl -n "$NS" get svc legacy-payments -o jsonpath='{.spec.type}')
[[ "$type" == "ExternalName" ]] || fail "service must be ExternalName"
target=$(kubectl -n "$NS" get svc legacy-payments -o jsonpath='{.spec.externalName}')
[[ "$target" == "payments-api.ckad-d5-006.svc.cluster.local" ]] || fail "wrong DNS alias: $target"
count=$(kubectl -n "$NS" get endpointslice -l kubernetes.io/service-name=payments-api -o jsonpath='{range .items[*].endpoints[*]}{.conditions.ready}{"\n"}{end}' | grep -c '^true$' || true)
[[ "$count" -ge 2 ]] || fail "expected 2 ready backend endpoints, got $count"
kubectl -n "$NS" exec checkout-client -- nslookup legacy-payments.ckad-d5-006.svc.cluster.local >/dev/null || fail "alias DNS lookup failed"
body=$(kubectl -n "$NS" exec checkout-client -- wget -qO- -T 5 http://legacy-payments.ckad-d5-006.svc.cluster.local:8080/ 2>/dev/null) || fail "HTTP request via alias failed"
[[ "$body" == *"payments-ok"* ]] || fail "unexpected response: $body"
echo "PASS: ExternalName target, ready endpoints, DNS and HTTP verified on Kubernetes"
