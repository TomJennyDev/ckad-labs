#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-007}"
ensure_cluster
ensure_owner "$NS"
k -n "$NS" apply -f "$D/solution.yaml"
k -n "$NS" rollout status statefulset/report-shard --timeout=240s
