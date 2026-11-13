#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTX="${CTX:-kind-ckad-labs}" NS="${NS:-ckad-d2-010}"
k() { kubectl --context "$CTX" -n "$NS" "$@"; }
case "${1:-}" in
  no-canary) k scale deploy/storefront-canary --replicas=0 ;;
  wrong-selector) k patch svc storefront --type=merge -p '{"spec":{"selector":{"app":"storefront","track":"stable"}}}' ;;
  too-many-canary) k scale deploy/storefront-canary --replicas=3 ;;
  no-stable) k scale deploy/storefront-stable --replicas=0 ;;
  bad-image) k set image deploy/storefront-canary web=nginx:nonexistent-ckad-tag ;;
  *) echo "Usage: $0 {no-canary|wrong-selector|too-many-canary|no-stable|bad-image}" >&2; exit 2 ;;
esac
echo "Fault injected; wait for reconciliation then run verify.sh (must fail). Restore: kubectl apply -f setup.yaml && ./solution.sh"
