#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-002
fail(){ echo "FAIL D5-002: $*" >&2; exit 1; }
kubectl -n "$NS" rollout status deploy/payments-api --timeout=180s >/dev/null || fail "Deployment not ready"
kubectl -n "$NS" wait --for=condition=Ready pod/checkout-client --timeout=180s >/dev/null || fail "client not ready"
kubectl -n "$NS" get svc payments -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]
assert s["type"]=="ClusterIP" and s["selector"]=={"app":"payments-api"}
assert len(s["ports"])==1
p=s["ports"][0]
assert p["port"]==80 and p["targetPort"]=="http-app" and p["protocol"]=="TCP"
assert not s.get("externalIPs")
' || fail "Service must use port 80 and named targetPort http-app"
kubectl -n "$NS" get deploy payments-api -o json | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d["spec"]["replicas"]==2 and d["status"].get("readyReplicas",0)==2
c=d["spec"]["template"]["spec"]["containers"][0]
assert c["ports"][0]["name"]=="http-app" and c["ports"][0]["containerPort"]==9090
assert c["readinessProbe"]["tcpSocket"]["port"]=="http-app"
' || fail "backend ports/probe/replicas changed"
kubectl -n "$NS" get pods -l app=payments-api -o json | python3 -c '
import json,sys
pods=json.load(sys.stdin)["items"]
assert len(pods)==2
assert all(any(c["type"]=="Ready" and c["status"]=="True" for c in p["status"].get("conditions",[])) for p in pods)
' || fail "two Ready backend Pods required"
ready=0
for attempt in $(seq 1 30); do
  if kubectl -n "$NS" get endpointslices -l kubernetes.io/service-name=payments -o json | python3 -c '
import json,sys
items=json.load(sys.stdin)["items"]
eps=[e for s in items for e in s.get("endpoints",[]) if e.get("conditions",{}).get("ready",True)]
assert len(eps)==2
assert len({ip for e in eps for ip in e["addresses"]})==2
assert all(e.get("targetRef",{}).get("kind")=="Pod" for e in eps)
assert all(any(p.get("port")==9090 and p.get("protocol")=="TCP" for p in s.get("ports",[])) for s in items if s.get("endpoints"))
'; then ready=1; break; fi
  sleep 3
done
test "$ready" = 1 || fail "EndpointSlice not reconciled to 9090"
output=$(kubectl -n "$NS" exec checkout-client -- wget -q -T 5 -O - http://payments:80/ 2>&1) || fail "in-cluster HTTP failed: $output"
test "$output" = "payments-ok" || fail "wrong HTTP body: $output"
echo "PASS D5-002: Service 80 -> named targetPort -> Pod 9090, HTTP 200"
