#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
NS=ckad-d5-012
[[ "$(kubectl config current-context)" == "kind-ckad-d5-012" ]] || { echo "Wrong kube context" >&2; exit 1; }
command -v openssl >/dev/null
kubectl apply -f "$DIR/setup.yaml"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 3 \
  -keyout "$tmp/tls.key" -out "$tmp/tls.crt" \
  -subj "/CN=secure.ckad.local" -addext "subjectAltName=DNS:secure.ckad.local" >/dev/null 2>&1
kubectl -n "$NS" create secret tls orders-tls --cert="$tmp/tls.crt" --key="$tmp/tls.key" \
  --dry-run=client -o yaml | kubectl apply -f -
cp "$tmp/tls.crt" "$DIR/.lab-ca.crt"
echo "Broken ingress installed; public trust cert: $DIR/.lab-ca.crt"
