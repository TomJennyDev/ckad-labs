#!/usr/bin/env bash
set -euo pipefail
K=(kubectl --context kind-ckad-labs -n ckad-d4-002)
fail(){ echo "FAIL: $*" >&2; exit 1; }
[[ "$(kubectl config current-context)" == "kind-ckad-labs" ]] || fail "current kubectl context must be kind-ckad-labs"
kubectl get ns ckad-d4-002 >/dev/null || fail "namespace missing"
[[ "$("${K[@]}" get secret billing-credentials -o jsonpath='{.data.api-key}' | base64 -d)" == "key-v2" ]] || fail "Secret must be rotated to key-v2"
[[ "$("${K[@]}" get deploy billing-worker -o jsonpath='{.spec.template.spec.volumes[0].secret.secretName}')" == "billing-credentials" ]] || fail "Secret volume missing"
[[ "$("${K[@]}" get deploy billing-worker -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.secretKeyRef.name}')" == "billing-credentials" ]] || fail "env secretKeyRef missing"
[[ "$("${K[@]}" get deploy billing-worker -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}')" == "true" ]] || fail "mount not readOnly"
[[ -z "$("${K[@]}" get deploy billing-worker -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].subPath}')" ]] || fail "subPath prevents rotation"
"${K[@]}" rollout status deploy/billing-worker --timeout=120s >/dev/null || fail "Deployment unavailable"
pod=$("${K[@]}" get pod -l app=billing-worker -o jsonpath='{.items[0].metadata.name}')
[[ -n "$pod" ]] || fail "Pod missing"
uid=$("${K[@]}" get pod "$pod" -o jsonpath='{.metadata.uid}')
baseline=$(kubectl get ns ckad-d4-002 -o jsonpath='{.metadata.annotations.ckad\.dev/baseline-uid}')
[[ -n "$baseline" && "$uid" == "$baseline" ]] || fail "Pod UID changed or baseline missing"
[[ "$("${K[@]}" exec "$pod" -c worker -- printenv BOOT_API_KEY)" == "key-v1" ]] || fail "env snapshot should remain key-v1"
for i in $(seq 1 30); do
  value=$("${K[@]}" exec "$pod" -c worker -- cat /var/run/credentials/api-key 2>/dev/null || true)
  [[ "$value" == "key-v2" ]] && { echo "PASS: Secret rotated in projected volume; env snapshot and Pod UID unchanged"; exit 0; }
  sleep 5
done
fail "projected volume did not update to key-v2 in 150 seconds"
