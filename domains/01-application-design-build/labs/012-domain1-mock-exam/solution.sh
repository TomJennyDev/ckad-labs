#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d1-012}"
ensure_cluster
ensure_owner "$NS"
k -n "$NS" apply -f "$D/solution.yaml"
k -n "$NS" rollout status deployment/gateway --timeout=180s
k -n "$NS" wait --for=condition=complete job/batch-report --timeout=180s
echo "Reference solution applied to $NS. Run ./ckad domain check D1-012"
