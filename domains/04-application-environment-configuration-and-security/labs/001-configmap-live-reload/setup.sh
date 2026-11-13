#!/usr/bin/env bash
set -euo pipefail
K=(kubectl --context kind-ckad-labs)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${K[@]}" apply -f "$DIR/setup.yaml"
"${K[@]}" -n ckad-d4-001 rollout status deploy/pricing-api --timeout=180s
uid="$("${K[@]}" -n ckad-d4-001 get pods -l app=pricing-api -o jsonpath='{.items[0].metadata.uid}')"
[[ -n "$uid" ]]
"${K[@]}" annotate ns ckad-d4-001 "ckad-labs.io/baseline-uid=$uid" --overwrite
echo "Baseline Pod UID: $uid"
