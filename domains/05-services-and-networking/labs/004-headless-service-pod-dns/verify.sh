#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-004
fail(){ echo "FAIL D5-004: $*" >&2; exit 1; }
kubectl get ns "$NS" >/dev/null || fail "namespace"
kubectl -n "$NS" rollout status sts/ledger --timeout=180s >/dev/null || fail "statefulset rollout"
kubectl -n "$NS" wait --for=condition=Ready pod/dns-client pod/ledger-0 pod/ledger-1 --timeout=180s >/dev/null || fail "pod readiness"
kubectl -n "$NS" get sts ledger -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)
assert s["spec"]["serviceName"]=="peer-discovery"
assert s["spec"]["replicas"]==2 and s["status"].get("readyReplicas")==2
' || fail "StatefulSet identity"
kubectl -n "$NS" get svc peer-discovery -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]
assert s["clusterIP"]=="None" and s["selector"]=={"app":"ledger"}
assert s["ports"][0]["port"]==8080 and s["ports"][0]["targetPort"]=="http"
' || fail "headless Service contract"
kubectl -n "$NS" get pod ledger-0 ledger-1 -o json | python3 -c '
import json,sys
pods=json.load(sys.stdin)["items"]
assert len(pods)==2
for p in pods:
 assert p["spec"]["hostname"] in ("ledger-0","ledger-1")
 assert p["spec"]["subdomain"]=="peer-discovery"
 assert any(c["type"]=="Ready" and c["status"]=="True" for c in p["status"]["conditions"])
' || fail "Pod hostname/subdomain (stale Pods?)"
for ordinal in 0 1; do
  host="ledger-$ordinal.peer-discovery.$NS.svc.cluster.local"
  kubectl -n "$NS" exec dns-client -- nslookup "$host" >/dev/null || fail "DNS $host"
  result=$(kubectl -n "$NS" exec dns-client -- wget -q -T 8 -O - "http://$host:8080/") || fail "HTTP $host"
  test "$result" = "ledger-peer-ok" || fail "response from $host: $result"
done
echo "PASS D5-004: headless Service, per-Pod DNS and HTTP on both peers"
