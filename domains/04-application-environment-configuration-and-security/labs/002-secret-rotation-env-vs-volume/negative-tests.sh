#!/usr/bin/env bash
set -euo pipefail
K=(kubectl --context kind-ckad-labs -n ckad-d4-002)
pod=$("${K[@]}" get pod -l app=billing-worker -o jsonpath='{.items[0].metadata.name}')
[[ -n "$pod" ]] || { echo 'FAIL: run setup.sh first'; exit 1; }
before=$("${K[@]}" exec "$pod" -- printenv BOOT_API_KEY)
[[ "$before" == "key-v1" ]] || { echo "FAIL: env baseline not key-v1"; exit 1; }
"${K[@]}" patch secret billing-credentials --type=merge -p '{"stringData":{"api-key":"key-v2"}}' >/dev/null
sleep 5
after=$("${K[@]}" exec "$pod" -- printenv BOOT_API_KEY)
[[ "$after" == "key-v1" ]] || { echo 'FAIL: env changed without Pod restart'; exit 1; }
echo 'PASS negative: Secret env is NOT live-reloaded (expected behavior)'
# A second negative check: missing secret key cannot be read as an alternative.
if "${K[@]}" get secret billing-credentials -o jsonpath='{.data.missing-key}' | grep -q .; then
  echo 'FAIL: unexpected missing-key exists'; exit 1
fi
echo 'PASS negative: nonexistent key is absent'
