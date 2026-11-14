#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-014
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/setup.yaml" >/dev/null
kubectl -n "$NS" rollout status deployment/gateway --timeout=180s >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then echo "FAIL: broken configuration passed verifier" >&2; exit 1; fi
echo "PASS negative: verifier rejects Secret 0400 without fsGroup"
echo "Restore: bash solution.sh"
