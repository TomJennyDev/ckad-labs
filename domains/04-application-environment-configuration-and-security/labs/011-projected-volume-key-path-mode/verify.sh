#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-011
fail(){ echo "FAIL: $*" >&2; exit 1; }
kubectl get namespace "$NS" >/dev/null || fail "namespace missing"
kubectl -n "$NS" get configmap gateway-settings >/dev/null || fail "ConfigMap missing"
kubectl -n "$NS" get secret gateway-credential >/dev/null || fail "Secret missing"
json=$(kubectl -n "$NS" get deploy billing-gateway -o json)
printf '%s' "$json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
v=d["spec"]["template"]["spec"]["volumes"][0]["projected"]
assert v.get("defaultMode")==288, "defaultMode must be decimal 288 (0440)"
sources=v["sources"]
assert sources[0]["configMap"]["name"]=="gateway-settings"
assert sources[0]["configMap"]["items"]==[{"key":"app.yaml","path":"config/app.yaml"}]
assert sources[1]["secret"]["name"]=="gateway-credential"
assert sources[1]["secret"]["items"]==[{"key":"token","path":"credentials/token"}]
' || fail "projected volume configuration"
kubectl -n "$NS" rollout status deploy/billing-gateway --timeout=60s >/dev/null || fail "rollout not ready"
pod=$(kubectl -n "$NS" get pod -l app=billing-gateway -o jsonpath='{.items[0].metadata.name}')
[ -n "$pod" ] || fail "pod missing"
kubectl -n "$NS" exec "$pod" -- sh -ec '
  test -r /etc/gateway/config/app.yaml
  test -r /etc/gateway/credentials/token
  grep -q "retries: 3" /etc/gateway/config/app.yaml
  test "$(cat /etc/gateway/credentials/token)" = demo-token-v1
  test "$(stat -c %a /etc/gateway/config/app.yaml)" = 440
  test "$(stat -c %a /etc/gateway/credentials/token)" = 440
' || fail "live filesystem checks"
echo "PASS D4-011: Kubernetes spec, readiness, content and file modes"
