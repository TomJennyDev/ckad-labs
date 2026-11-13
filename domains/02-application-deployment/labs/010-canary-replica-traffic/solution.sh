#!/usr/bin/env bash
set -euo pipefail
NS="${NS:-ckad-d2-010}"
CTX="${CTX:-kind-ckad-labs}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl --context "$CTX" get namespace "$NS" >/dev/null
kubectl --context "$CTX" -n "$NS" apply -f "$DIR/solution.yaml"
kubectl --context "$CTX" -n "$NS" rollout status deploy/storefront-stable --timeout=180s
kubectl --context "$CTX" -n "$NS" rollout status deploy/storefront-canary --timeout=180s
echo "Canary ready; run verify.sh"
