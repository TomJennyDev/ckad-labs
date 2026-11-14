#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-013
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/setup.yaml" >/dev/null
kubectl -n "$NS" delete pod ledger-api --ignore-not-found --wait=true
kubectl apply -f "$DIR/setup.yaml" >/dev/null
kubectl -n "$NS" wait --for=condition=Ready pod/ledger-api --timeout=120s >/dev/null
if kubectl -n "$NS" exec ledger-api -c reader -- cat /shared/ledger.txt >/dev/null 2>&1; then
  echo "FAIL: expected permission denied with mode 0600" >&2; exit 1
fi
echo "PASS negative: Pod Ready but reader cannot read mode 0600"
