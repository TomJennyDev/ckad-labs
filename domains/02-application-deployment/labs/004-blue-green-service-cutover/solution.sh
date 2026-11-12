#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-004}"
ensure_cluster
ensure_owner "$NS"
k -n "$NS" rollout status deploy/storefront-blue --timeout=180s
k -n "$NS" rollout status deploy/storefront-green --timeout=180s
# Do not switch traffic until the candidate is healthy.
k -n "$NS" wait --for=condition=available deploy/storefront-green --timeout=180s
k -n "$NS" patch svc storefront --type=merge -p '{"spec":{"selector":{"app":"storefront","track":"green"}}}'
k -n "$NS" get svc storefront -o wide
