#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-001
fail(){ echo "FAIL D5-001: $*" >&2; exit 1; }
kubectl -n "$NS" rollout status deployment/inventory-api --timeout=180s >/dev/null || fail "backend not ready"
kubectl -n "$NS" wait --for=condition=Ready pod/storefront --timeout=180s >/dev/null || fail "client not ready"
kubectl -n "$NS" get service inventory-api -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]
assert s["type"]=="ClusterIP", "service type changed"
assert s["selector"]=={"app":"inventory-api"}, "wrong selector"
assert len(s["ports"])==1 and s["ports"][0]["port"]==8080 and s["ports"][0]["targetPort"]==8080, "wrong port"
assert not s.get("externalIPs"), "external IP not allowed"
' || fail "Service spec"
kubectl -n "$NS" get deployment inventory-api -o json | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d["spec"]["replicas"]==2
assert d["spec"]["template"]["metadata"]["labels"]["app"]=="inventory-api"
assert d["status"].get("readyReplicas",0)==2
' || fail "Deployment spec or readiness"
kubectl -n "$NS" get pods -l app=inventory-api -o json | python3 -c '
import json,sys
p=json.load(sys.stdin)["items"]
assert len(p)==2 and all(any(c["type"]=="Ready" and c["status"]=="True" for c in x["status"].get("conditions",[])) for x in p)
' || fail "two backend pods not Ready"
# EndpointSlice controller convergence is asynchronous; inspect live API state, never fabricated values.
ready=0
for attempt in $(seq 1 30); do
  if kubectl -n "$NS" get endpointslices -l kubernetes.io/service-name=inventory-api -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["items"]
eps=[e for x in s for e in x.get("endpoints",[]) if e.get("conditions",{}).get("ready",True)]
assert len(eps)==2, f"expected 2 ready endpoints, got {len(eps)}"
assert len({a for e in eps for a in e["addresses"]})==2
assert all(e.get("targetRef",{}).get("kind")=="Pod" for e in eps)
'; then ready=1; break; fi
  sleep 3
done
test "$ready" = 1 || fail "EndpointSlice not reconciled to 2 ready Pods"
output=$(kubectl -n "$NS" exec storefront -- wget -q -T 5 -O - http://inventory-api:8080/ 2>&1) || fail "HTTP from client failed: $output"
test "$output" = "inventory-ok" || fail "unexpected HTTP body: $output"
echo "PASS D5-001: two Ready endpoints and in-cluster HTTP 200"
