#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/solution.sh"
"$DIR/verify.sh"
kubectl -n ckad-d5-011 patch ingress storefront --type=json -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/name","value":"checkout"}]'
if "$DIR/verify.sh"; then echo "FAIL: swapped backend not detected"; exit 1; fi
"$DIR/solution.sh"
"$DIR/verify.sh"
echo "PASS: negative test detected misroute and restored correct state"
