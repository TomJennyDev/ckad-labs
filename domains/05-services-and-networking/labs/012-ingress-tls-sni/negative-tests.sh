#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
NS=ckad-d5-012
[[ "$(kubectl config current-context)" == "kind-ckad-d5-012" ]] || exit 1
"$DIR/solution.sh"
"$DIR/verify.sh"
restore(){ "$DIR/solution.sh" >/dev/null || true; }
trap restore EXIT
kubectl -n "$NS" patch ingress orders-gateway --type=json -p='[{"op":"replace","path":"/spec/tls/0/secretName","value":"legacy-tls"}]'
if "$DIR/verify.sh"; then echo "FAIL: grader accepted wrong TLS secret" >&2; exit 1; fi
restore
trap - EXIT
"$DIR/verify.sh"
echo "PASS: negative test detected invalid TLS reference and restored state"
