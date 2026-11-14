#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-012
fail(){ echo "FAIL D4-012: $*" >&2; exit 1; }
kubectl get ns "$NS" >/dev/null || fail "namespace missing"
kubectl -n "$NS" get cm pricing-config >/dev/null || fail "ConfigMap missing"
[ "$(kubectl -n "$NS" get cm pricing-config -o jsonpath='{.data.price\.txt}')" = 200 ] || fail "ConfigMap must be version 200"
kubectl -n "$NS" get deploy pricing-api -o json | python3 -c '
import json,sys
d=json.load(sys.stdin)
s=d["spec"]
assert s["replicas"]==1
c=s["template"]["spec"]["containers"][0]
m=c["volumeMounts"][0]
assert m["mountPath"]=="/etc/pricing" and "subPath" not in m
assert m.get("readOnly") is True
v=s["template"]["spec"]["volumes"][0]
assert v["configMap"]["name"]=="pricing-config"
' || fail "Deployment must mount directory without subPath"
kubectl -n "$NS" rollout status deploy/pricing-api --timeout=90s >/dev/null || fail "Deployment not ready"
for attempt in $(seq 1 45); do
  pods=$(kubectl -n "$NS" get pods -l app=pricing-api -o jsonpath='{range .items[*]}{.metadata.name}{" "}{end}')
  count=0
  ok=0
  for pod in $pods; do
    count=$((count+1))
    if kubectl -n "$NS" exec "$pod" -- sh -c '[ "$(cat /etc/pricing/price.txt)" = 200 ]' >/dev/null 2>&1; then ok=$((ok+1)); fi
  done
  if [ "$count" -eq 1 ] && [ "$ok" -eq 1 ]; then echo "PASS D4-012: live projected ConfigMap updated to 200"; exit 0; fi
  sleep 4
done
fail "live Pod file did not refresh to 200 within 180s"
