#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-009
[[ "$(kubectl config current-context)" == kind-ckad-labs ]] || exit 2
# Destructive negative tests are isolated in a separate namespace.
TEST_NS="ckad-d3-009-negative"
trap 'kubectl delete namespace "$TEST_NS" --ignore-not-found --wait=false >/dev/null 2>&1 || true' EXIT
kubectl create namespace "$TEST_NS" >/dev/null 2>&1 || true
kubectl -n "$TEST_NS" create deployment broken --image=nginx:1.27-alpine --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "$TEST_NS" patch deployment broken --type=strategic -p '{"spec":{"template":{"spec":{"volumes":[{"name":"missing","secret":{"secretName":"missing-secret","optional":false}}],"containers":[{"name":"nginx","volumeMounts":[{"name":"missing","mountPath":"/etc/missing","readOnly":true}]}]}}}}' >/dev/null
echo 'Waiting for kubelet to report FailedMount in isolated namespace...'
found=0
for i in $(seq 1 24); do
  if kubectl -n "$TEST_NS" get events --field-selector reason=FailedMount -o jsonpath='{range .items[*]}{.message}{"\n"}{end}' 2>/dev/null | grep -q 'missing-secret'; then found=1; break; fi
  sleep 5
done
[[ "$found" -eq 1 ]] || { echo 'FAIL: FailedMount not observed (check scheduling, node and image pulls)'; exit 1; }
echo 'PASS: missing non-optional Secret causes FailedMount'
kubectl -n "$TEST_NS" create secret generic missing-secret --from-literal=token=demo >/dev/null
kubectl -n "$TEST_NS" rollout status deployment/broken --timeout=120s
echo 'PASS: mounting succeeds after Secret exists'
