#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "FAIL D5-003: $*" >&2; exit 1; }
kubectl -n ckad-d5-003-backend rollout status deploy/catalog --timeout=180s >/dev/null || fail "backend rollout"
kubectl -n ckad-d5-003 wait --for=condition=Ready pod/storefront --timeout=180s >/dev/null || fail "client readiness"
kubectl -n ckad-d5-003 get pod storefront -o json | python3 -c '
import json,sys
p=json.load(sys.stdin)
assert p["metadata"]["namespace"]=="ckad-d5-003"
env={e["name"]:e.get("value") for c in p["spec"]["containers"] for e in c.get("env",[])}
assert env["CATALOG_URL"]=="http://catalog.ckad-d5-003-backend.svc.cluster.local:80/"
' || fail "wrong cross-namespace FQDN"
kubectl -n ckad-d5-003-backend get deploy catalog -o json | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d["spec"]["replicas"]==2 and d["status"].get("readyReplicas",0)==2
' || fail "backend replicas"
kubectl -n ckad-d5-003-backend get svc catalog -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]
assert s["type"]=="ClusterIP" and s["selector"]=={"app":"catalog"}
assert len(s["ports"])==1 and s["ports"][0]["port"]==80 and s["ports"][0]["targetPort"]=="http"
' || fail "Service contract"
url=$(kubectl -n ckad-d5-003 exec storefront -- printenv CATALOG_URL) || fail "client env"
out=$(kubectl -n ckad-d5-003 exec storefront -- wget -q -T 8 -O - "$url") || fail "cross-namespace HTTP"
test "$out" = catalog-ok || fail "response $out"
echo "PASS D5-003: cross-namespace DNS and live HTTP"
