#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
NS=ckad-d5-012
fail(){ echo "FAIL D5-012: $*" >&2; exit 1; }
[[ "$(kubectl config current-context)" == "kind-ckad-d5-012" ]] || fail "wrong context"
for bin in kubectl curl openssl base64; do command -v "$bin" >/dev/null || fail "$bin missing"; done
[[ -s "$DIR/.lab-ca.crt" ]] || fail "missing .lab-ca.crt; run bootstrap.sh"
kubectl get ns "$NS" >/dev/null || fail "namespace absent"
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=120s >/dev/null || fail "controller not ready"
kubectl -n "$NS" rollout status deployment/orders --timeout=120s >/dev/null || fail "orders not ready"
count="$(kubectl -n "$NS" get endpointslice -l kubernetes.io/service-name=orders -o jsonpath='{range .items[*].endpoints[*]}{.conditions.ready}{"\n"}{end}' | grep -c '^true$' || true)"
[[ "$count" -ge 2 ]] || fail "expected 2 ready endpoints, got $count"
[[ "$(kubectl -n "$NS" get secret orders-tls -o jsonpath='{.type}')" == kubernetes.io/tls ]] || fail "TLS secret type"
crt="$(kubectl -n "$NS" get secret orders-tls -o jsonpath='{.data.tls\.crt}' | base64 -d)"
key="$(kubectl -n "$NS" get secret orders-tls -o jsonpath='{.data.tls\.key}' | base64 -d)"
[[ -n "$key" ]] || fail "TLS private key missing"
printf '%s\n' "$crt" | openssl x509 -noout -ext subjectAltName | grep -q 'DNS:secure.ckad.local' || fail "certificate SAN mismatch"
printf '%s\n' "$crt" | openssl x509 -noout -checkend 0 >/dev/null || fail "certificate expired"
[[ "$(kubectl -n "$NS" get ingress orders-gateway -o jsonpath='{.spec.ingressClassName}')" == nginx ]] || fail "IngressClass mismatch"
[[ "$(kubectl -n "$NS" get ingress orders-gateway -o jsonpath='{.spec.tls[0].hosts[0]}')" == secure.ckad.local ]] || fail "TLS host mismatch"
[[ "$(kubectl -n "$NS" get ingress orders-gateway -o jsonpath='{.spec.tls[0].secretName}')" == orders-tls ]] || fail "wrong TLS secret reference"
[[ "$(kubectl -n "$NS" get ingress orders-gateway -o jsonpath='{.spec.rules[0].host}')" == secure.ckad.local ]] || fail "rule host mismatch"
[[ "$(kubectl -n "$NS" get ingress orders-gateway -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')" == orders ]] || fail "backend mismatch"
[[ "$(kubectl -n "$NS" get ingress orders-gateway -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}')" == 80 ]] || fail "backend port mismatch"
ok=0
for attempt in $(seq 1 20); do
  body="$(curl --noproxy '*' --cacert "$DIR/.lab-ca.crt" --resolve secure.ckad.local:8443:127.0.0.1 -fsS --max-time 5 https://secure.ckad.local:8443/ 2>/dev/null || true)"
  if [[ "$body" == orders-secure-ok ]]; then ok=1; break; fi
  sleep 2
done
[[ "$ok" == 1 ]] || fail "verified HTTPS response unavailable; check TLS, SNI, endpoint"
echo "PASS D5-012: Kubernetes readiness, TLS Secret, SAN, Ingress, verified HTTPS and HTTP response"
