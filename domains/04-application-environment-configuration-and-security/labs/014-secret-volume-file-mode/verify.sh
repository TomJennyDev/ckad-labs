#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-014
fail(){ echo "FAIL: $*" >&2; exit 1; }
kubectl -n "$NS" rollout status deployment/gateway --timeout=120s >/dev/null || fail "rollout not ready"
kubectl -n "$NS" get deployment gateway -o json | python3 -c '
import json,sys
p=json.load(sys.stdin)["spec"]
assert p["replicas"]==2
s=p["template"]["spec"]
assert s["securityContext"]["runAsNonRoot"] is True
assert s["securityContext"]["runAsUser"]==10001
assert s["securityContext"]["fsGroup"]==10001
v=next(v for v in s["volumes"] if v["name"]=="credentials")
assert v["secret"]["secretName"]=="gateway-credentials"
assert v["secret"]["defaultMode"]==288
assert s["containers"][0]["volumeMounts"][0]["readOnly"] is True
' || fail "insecure or incorrect spec"
pods="$(kubectl -n "$NS" get pods -l app=gateway -o json)"
printf '%s' "$pods" | python3 -c 'import json,sys; p=json.load(sys.stdin)["items"]; assert len(p)==2 and all(x["status"].get("phase")=="Running" for x in p)' || fail "not two running pods"
for pod in $(kubectl -n "$NS" get pods -l app=gateway -o jsonpath='{.items[*].metadata.name}'); do
  result="$(kubectl -n "$NS" exec "$pod" -c gateway -- sh -c 'id -u; id -G; stat -c %a /var/run/credentials/token; cat /var/run/credentials/token')" || fail "exec $pod"
  echo "$result" | grep -qx '10001' || fail "UID $pod"
  echo "$result" | grep -Eq '(^| )10001( |$)' || fail "group $pod"
  echo "$result" | grep -qx '440' || fail "mode $pod"
  echo "$result" | grep -qx 'lab-demo-token' || fail "token unreadable $pod"
  echo "PASS $pod"
done
echo "PASS D4-014: both nonroot pods read group-restricted Secret"
