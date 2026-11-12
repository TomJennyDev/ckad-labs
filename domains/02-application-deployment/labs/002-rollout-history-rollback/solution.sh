#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-002}"
ensure_cluster
ensure_owner "$NS"
# A rollback creates a NEW revision; never delete the Deployment (which erases history).
k -n "$NS" rollout undo deployment/payments
k -n "$NS" rollout status deployment/payments --timeout=150s
echo "Rollback complete; inspect history: kubectl --context kind-ckad-labs -n $NS rollout history deploy/payments"
