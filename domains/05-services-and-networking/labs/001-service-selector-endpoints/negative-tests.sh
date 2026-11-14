#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS=ckad-d5-001
kubectl -n "$NS" get service inventory-api >/dev/null
kubectl -n "$NS" patch service inventory-api --type=merge -p '{"spec":{"selector":{"app":"inventory-v2"}}}' >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then
  echo "FAIL negative: verifier accepted broken selector" >&2
  exit 1
fi
echo "PASS negative: broken selector rejected by verifier"
echo "Restore: bash $DIR/solution.sh"
