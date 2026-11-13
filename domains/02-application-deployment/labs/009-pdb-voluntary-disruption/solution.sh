#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS="${NS:-ckad-d2-009}"
K=(kubectl --context kind-ckad-labs -n "$NS")
"${K[@]}" apply -f "$DIR/solution.yaml"
"${K[@]}" rollout status deployment/checkout --timeout=180s
"${K[@]}" wait --for=jsonpath='{.status.currentHealthy}'=3 pdb/checkout-availability --timeout=90s
