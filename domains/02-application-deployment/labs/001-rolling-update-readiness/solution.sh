#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-001}"
ensure_cluster
ensure_owner "$NS"
k -n "$NS" apply -f "$D/solution.yaml"
k -n "$NS" rollout status deployment/checkout --timeout=180s
echo "Applied reference solution. Check: ./ckad domain check D2-001"
