#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-005
fail(){ echo "FAIL D5-005: $*" >&2; exit 1; }
kubectl get namespace "$NS" >/dev/null || fail namespace
for d in orders-blue orders-green; do
  kubectl -n "$NS" rollout status deployment/"$d" --timeout=180s >/dev/null || fail "$d not ready"
done
kubectl -n "$NS" wait --for=condition=Ready pod/client-a pod/client-b --timeout=180s >/dev/null || fail clients
kubectl -n "$NS" get svc orders -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]
assert s["type"]=="ClusterIP"
assert s["sessionAffinity"]=="ClientIP"
assert s["sessionAffinityConfig"]["clientIP"]["timeoutSeconds"]==10800
assert s["selector"]=={"app":"orders"}
assert s["ports"][0]["port"]==80 and s["ports"][0]["targetPort"]=="http"
' || fail "Service spec"
kubectl -n "$NS" get endpointslices -l kubernetes.io/service-name=orders -o json | python3 -c '
import json,sys
items=json.load(sys.stdin)["items"]
addresses={a for item in items for e in item.get("endpoints",[]) if e.get("conditions",{}).get("ready",True) for a in e["addresses"]}
assert len(addresses)==2,addresses
' || fail "expected two ready backend IPs"
for client in client-a client-b; do
  first=""
  for i in $(seq 1 12); do
    result=$(kubectl -n "$NS" exec "$client" -- wget -q -T 5 -O - http://orders:80/) || fail "HTTP $client iteration $i"
    [[ "$result" == blue || "$result" == green ]] || fail "unexpected response $result"
    if [[ -z "$first" ]]; then first="$result"; fi
    [[ "$result" == "$first" ]] || fail "affinity broken: $client switched $first -> $result"
  done
  echo "$client: 12/12 responses=$first"
done
echo "PASS D5-005: Service ClientIP affinity and real HTTP checks"
