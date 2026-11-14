#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "FAIL: $*" >&2; exit 1; }
command -v kubectl >/dev/null || fail "kubectl required"
command -v python3 >/dev/null || fail "python3 required"
command -v curl >/dev/null || fail "curl required"
command -v kind >/dev/null || fail "kind required"
kubectl config current-context | grep -q '^kind-' || fail "current context must be a kind cluster"
kind get clusters | grep -Fxq "${KIND_CLUSTER:-ckad-d5-010}" || fail "dedicated kind cluster not found"
kubectl -n ckad-d5-010 rollout status deployment/shipping-api --timeout=120s >/dev/null || fail "deployment not ready"
json=$(kubectl -n ckad-d5-010 get svc shipping-public -o json) || fail "Service missing"
printf '%s' "$json" | python3 -c '
import json,sys
s=json.load(sys.stdin); p=s["spec"]["ports"]
assert s["spec"]["type"]=="NodePort", "type"
assert s["spec"]["selector"]=={"app":"shipping-api"}, "selector"
assert len(p)==1 and p[0]["port"]==80 and p[0]["nodePort"]==30080 and p[0]["targetPort"]=="http", "ports"
' || fail "Service specification mismatch"
eps=$(kubectl -n ckad-d5-010 get endpointslices -l kubernetes.io/service-name=shipping-public -o json)
printf '%s' "$eps" | python3 -c '
import json,sys
items=json.load(sys.stdin)["items"]
ready=[e for i in items for e in i.get("endpoints",[]) if e.get("conditions",{}).get("ready") is True]
ports=[p.get("port") for i in items for p in i.get("ports",[])]
assert len(ready)>=2 and 5678 in ports, (len(ready),ports)
' || fail "EndpointSlice not ready or wrong backend port"
# Verify actual host->kind control-plane port mapping and HTTP. Never accept YAML alone.
for i in $(seq 1 12); do
  body=$(curl --noproxy '*' --silent --show-error --max-time 3 --fail http://127.0.0.1:18080/ 2>/dev/null || true)
  [ "$body" = shipping-ok ] && { echo "PASS: real host HTTP via kind NodePort; 2 ready endpoints"; exit 0; }
  sleep 2
done
fail "host HTTP 127.0.0.1:18080 did not return shipping-ok (kind mapping, kube-proxy, targetPort)"
