#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-002}"
ensure_cluster
ensure_owner "$NS"
# Non-destructive demonstration: trigger a broken revision; leave recovery to the student.
k -n "$NS" rollout status deployment/payments --timeout=120s
k -n "$NS" set image deployment/payments web=nginx:missing-ckad-d2-002
echo "Injected broken release. Observe: kubectl --context kind-ckad-labs -n $NS get pods -w"
echo "Recover using: kubectl --context kind-ckad-labs -n $NS rollout undo deployment/payments"
