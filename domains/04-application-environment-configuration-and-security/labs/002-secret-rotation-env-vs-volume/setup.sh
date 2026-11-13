#!/usr/bin/env bash
set -euo pipefail
K=(kubectl --context kind-ckad-labs -n ckad-d4-002)
[[ "$(kubectl config current-context)" == "kind-ckad-labs" ]] || { echo 'Switch to kind-ckad-labs context first' >&2; exit 1; }
kubectl --context kind-ckad-labs apply -f "$(dirname "$0")/setup.yaml"
"${K[@]}" rollout status deploy/billing-worker --timeout=180s
pod=$("${K[@]}" get pod -l app=billing-worker -o jsonpath='{.items[0].metadata.name}')
uid=$("${K[@]}" get pod "$pod" -o jsonpath='{.metadata.uid}')
kubectl --context kind-ckad-labs annotate ns ckad-d4-002 "ckad.dev/baseline-uid=$uid" --overwrite
echo "Baseline UID: $uid"
