#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS=ckad-d5-002
kubectl -n "$NS" get svc payments >/dev/null
kubectl -n "$NS" patch svc payments --type=json -p='[{"op":"replace","path":"/spec/ports/0/targetPort","value":8080}]' >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then
  echo "FAIL negative: wrong targetPort accepted" >&2; exit 1
fi
echo "PASS negative: wrong targetPort rejected"
echo "Restore: bash $DIR/solution.sh"
