#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-011
fail(){ echo "FAIL: $*" >&2; exit 1; }
command -v kubectl >/dev/null || fail "kubectl missing"
command -v curl >/dev/null || fail "curl missing"
kubectl get ns "$NS" >/dev/null || fail "namespace missing"
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=120s >/dev/null || fail "ingress controller not ready"
for app in catalog checkout; do
  kubectl -n "$NS" rollout status deployment/"$app" --timeout=120s >/dev/null || fail "$app not ready"
  count=$(kubectl -n "$NS" get endpointslice -l kubernetes.io/service-name="$app" -o jsonpath='{range .items[*].endpoints[*]}{.conditions.ready}{"\n"}{end}' | grep -c '^true$' || true)
  [[ "$count" -ge 2 ]] || fail "$app ready endpoints <2"
done
json=$(kubectl -n "$NS" get ingress storefront -o json)
node -e 'const x=JSON.parse(process.argv[1]);const p=x.spec.rules[0].http.paths; if(x.spec.ingressClassName!=="nginx"||x.spec.rules[0].host!=="shop.ckad.local"||p.length!==2||p[0].path!=="/catalog"||p[1].path!=="/checkout"||p[0].backend.service.name!=="catalog"||p[1].backend.service.name!=="checkout")process.exit(1)' "$json" || fail "Ingress spec incorrect (requires node)"
for pair in catalog checkout; do
  actual=$(curl -fsS --max-time 5 -H 'Host: shop.ckad.local' "http://127.0.0.1:8080/$pair" || true)
  [[ "$actual" == "$pair-ok" ]] || fail "/$pair returned '$actual'"
done
status=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H 'Host: wrong.ckad.local' http://127.0.0.1:8080/catalog || true)
[[ "$status" == 404 ]] || fail "wrong host should return 404; got $status"
echo "PASS D5-011: controller, endpoints, host/path routing, negative host"
