#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/setup.yaml" >/dev/null
kubectl -n ckad-d4-015 wait --for=condition=Ready pod/audit-client --timeout=180s >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then echo "FAIL: verifier accepted broken Role" >&2; exit 1; fi
echo "PASS negative: pods-only Role cannot read ConfigMaps"
echo "Restore: bash solution.sh"
