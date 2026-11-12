#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-003}"
ensure_cluster
ensure_owner "$NS"
k -n "$NS" rollout status deployment/catalog --timeout=150s
k -n "$NS" rollout pause deployment/catalog
# All edits to the paused PodTemplate become ONE new revision on resume.
k -n "$NS" set image deployment/catalog web=nginx:1.27-alpine
k -n "$NS" patch deployment catalog --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"release":"v2"},"annotations":{"ckad.dev/change-ticket":"CHG-203"}}}}}'
echo "Paused: inspect get rs -l app=catalog and confirm no new ReplicaSet."
k -n "$NS" rollout resume deployment/catalog
k -n "$NS" rollout status deployment/catalog --timeout=180s
