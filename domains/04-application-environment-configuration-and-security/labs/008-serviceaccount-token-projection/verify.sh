#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-008
fail(){ echo "FAIL: $*" >&2; exit 1; }
pass(){ echo "PASS: $*"; }
command -v kubectl >/dev/null || fail "kubectl missing"
kubectl get namespace "$NS" >/dev/null || fail "namespace missing"
kubectl -n "$NS" rollout status deploy/invoice-reader --timeout=180s >/dev/null || fail "deployment not ready"
json="$(kubectl -n "$NS" get deploy invoice-reader -o json)"
python3 -c '
import json,sys
d=json.loads(sys.argv[1]); t=d["spec"]["template"]["spec"]
assert t.get("serviceAccountName")=="invoice-reader"
assert t.get("automountServiceAccountToken") is False
c=next(x for x in t["containers"] if x["name"]=="worker")
v={x["name"]:x for x in t["volumes"]}
p=v["worker-token"]["projected"]["sources"]
s=next(x["serviceAccountToken"] for x in p if "serviceAccountToken" in x)
assert s=={"path":"token","audience":"https://kubernetes.default.svc","expirationSeconds":3600}
ca=v["worker-ca"]["configMap"]
assert ca["name"]=="kube-root-ca.crt"
assert {"key":"ca.crt","path":"ca.crt"} in ca["items"]
mounts={x["name"]:x for x in c["volumeMounts"]}
assert mounts["worker-token"]["mountPath"]=="/var/run/worker-auth" and mounts["worker-token"]["readOnly"]
assert mounts["worker-ca"]["mountPath"]=="/var/run/worker-ca" and mounts["worker-ca"]["readOnly"]
assert all(x.get("mountPath")!="/var/run/secrets/kubernetes.io/serviceaccount" for x in c["volumeMounts"])
' "$json" || fail "Pod spec invalid"
pass "projected token, audience, expiry, CA and mounts"
[[ "$(kubectl -n "$NS" get deploy invoice-reader -o jsonpath='{.status.readyReplicas}')" == "1" ]] || fail "not ready"
pass "live Pod Ready"
[[ "$(kubectl -n "$NS" get role invoice-config-reader -o jsonpath='{.rules[0].resourceNames[0]}')" == "invoice-settings" ]] || fail "Role changed"
[[ "$(kubectl -n "$NS" auth can-i get configmap/invoice-settings --as="system:serviceaccount:$NS:invoice-reader")" == yes ]] || fail "cannot read config"
[[ "$(kubectl -n "$NS" auth can-i get secrets --as="system:serviceaccount:$NS:invoice-reader")" == no ]] || fail "secrets overprivileged"
[[ "$(kubectl -n "$NS" auth can-i get configmap/other --as="system:serviceaccount:$NS:invoice-reader")" == no ]] || fail "configmap overprivileged"
pass "RBAC least privilege"
pod="$(kubectl -n "$NS" get pod -l app=invoice-reader -o jsonpath='{.items[0].metadata.name}')"
[[ -n "$pod" ]] || fail "Pod absent"
kubectl -n "$NS" exec "$pod" -- test -s /var/run/worker-auth/token || fail "token not mounted"
kubectl -n "$NS" exec "$pod" -- test -s /var/run/worker-ca/ca.crt || fail "CA not mounted"
if kubectl -n "$NS" exec "$pod" -- test -e /var/run/secrets/kubernetes.io/serviceaccount/token; then fail "default token mounted"; fi
pass "token and CA live mounts"
# Read fresh projected token, verify actual HTTPS API response inside running Pod (no log-only grading).
kubectl -n "$NS" exec "$pod" -- python -c '
import json,ssl,urllib.request
token=open("/var/run/worker-auth/token").read().strip()
ctx=ssl.create_default_context(cafile="/var/run/worker-ca/ca.crt")
req=urllib.request.Request("https://kubernetes.default.svc/api/v1/namespaces/ckad-d4-008/configmaps/invoice-settings",headers={"Authorization":"Bearer "+token})
with urllib.request.urlopen(req,context=ctx,timeout=10) as r:
    obj=json.load(r)
assert obj["metadata"]["name"]=="invoice-settings"
assert obj["data"]["currency"]=="VND"
' || fail "actual HTTPS API authentication failed"
pass "real Kubernetes API HTTPS request authenticated and authorized"
echo "PASS: D4-008 complete"
