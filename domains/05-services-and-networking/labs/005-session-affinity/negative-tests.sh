#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS=ckad-d5-005
kubectl -n "$NS" patch svc orders --type=merge -p '{"spec":{"sessionAffinity":"None","sessionAffinityConfig":null}}'
if bash "$DIR/verify.sh" >/dev/null 2>&1; then
  echo "FAIL: verifier accepted sessionAffinity=None" >&2
  exit 1
fi
echo "PASS negative: verifier rejected None; restore with bash solution.sh"
