#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d1-010}"
D="$(cd "$(dirname "$0")" && pwd)"
ensure_cluster
ensure_owner "$NS"
k -n "$NS" apply -f "$D/solution.yaml"
k -n "$NS" rollout status daemonset/node-observer --timeout=180s
k -n "$NS" get pods -l app=node-observer -o wide
