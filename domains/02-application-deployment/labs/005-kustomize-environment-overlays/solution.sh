#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-005}"
ensure_cluster
ensure_owner "$NS"
k -n "$NS" apply -k "$D/overlays/production"
k -n "$NS" rollout status deployment/inventory --timeout=180s
k -n "$NS" get deployment/inventory configmap -o wide
