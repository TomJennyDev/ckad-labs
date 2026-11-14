#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "FAIL: $*" >&2; exit 1; }
command -v kubectl >/dev/null || fail "kubectl is required"
command -v python3 >/dev/null || fail "python3 is required"
api=ckad-d5-009-api
trusted=ckad-d5-009-trusted
rogue=ckad-d5-009-rogue
kubectl -n "$api" rollout status deploy/billing-api --timeout=150s >/dev/null || fail "backend not ready"
for item in "$trusted authorized-client" "$trusted intruder" "$rogue spoofed-client"; do
  read -r ns pod <<<"$item"
  kubectl -n "$ns" wait --for=condition=Ready "pod/$pod" --timeout=120s >/dev/null || fail "$pod not ready"
done
kubectl get namespace "$trusted" -o json | python3 -c 'import json,sys; assert json.load(sys.stdin)["metadata"]["labels"]["access-tier"]=="trusted"' || fail "trusted namespace label"
kubectl get namespace "$rogue" -o json | python3 -c 'import json,sys; assert json.load(sys.stdin)["metadata"]["labels"]["access-tier"]=="rogue"' || fail "rogue namespace label"
kubectl -n "$api" get networkpolicy billing-ingress -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]
assert s["podSelector"]=={"matchLabels":{"app":"billing-api"}}
assert set(s["policyTypes"])=={"Ingress"}
rules=s.get("ingress",[])
assert len(rules)==1
r=rules[0]
assert len(r.get("from",[]))==1, "namespaceSelector and podSelector must share ONE from entry"
assert r["from"][0]=={"namespaceSelector":{"matchLabels":{"access-tier":"trusted"}},"podSelector":{"matchLabels":{"role":"billing-client"}}}
assert len(r.get("ports",[]))==1
assert r["ports"][0].get("protocol","TCP")=="TCP" and r["ports"][0]["port"]==5678
' || fail "policy must have least-privilege AND peer and TCP/5678"
# Query the Service IP directly: avoid DNS as a confounding factor for ingress tests.
ip=$(kubectl -n "$api" get service billing-api -o jsonpath='{.spec.clusterIP}')
[ -n "$ip" ] && [ "$ip" != None ] || fail "Service ClusterIP unavailable"
request(){
  kubectl -n "$1" exec "$2" -- curl --noproxy '*' -fsS --connect-timeout 2 --max-time 5 "http://$ip:80"
}
# CNI convergence: retry positive for up to 30 seconds.
ok=0
for i in $(seq 1 10); do
  if [ "$(request "$trusted" authorized-client 2>/dev/null | tr -d '\r\n')" = "billing-ok" ]; then ok=1; break; fi
  sleep 3
done
[ "$ok" = 1 ] || fail "authorized client cannot reach billing API"
# Denials must be observed from both untrusted sources.
for item in "$trusted intruder" "$rogue spoofed-client"; do
  read -r ns pod <<<"$item"
  # Multiple attempts detect transient enforcement and ensure no successful HTTP response.
  for i in 1 2 3; do
    if request "$ns" "$pod" >/dev/null 2>&1; then fail "$ns/$pod unexpectedly reached billing API (check CNI enforcement)"; fi
    sleep 1
  done
done
echo "PASS: exact AND ingress peer; authorized HTTP works; intruder and spoofed client denied"
