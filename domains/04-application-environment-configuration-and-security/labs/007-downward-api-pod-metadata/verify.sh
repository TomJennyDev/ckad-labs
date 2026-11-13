#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-007
fail(){ echo "FAIL: $*" >&2; exit 1; }
kubectl get namespace "$NS" >/dev/null || fail "namespace missing"
kubectl -n "$NS" rollout status deployment/identity-api --timeout=120s >/dev/null || fail "rollout"
[ "$(kubectl -n "$NS" get deploy identity-api -o jsonpath='{.status.readyReplicas}')" = 2 ] || fail "2 ready replicas required"
python3 - "$NS" <<'PY'
import json,subprocess,sys
ns=sys.argv[1]
def k(*args): return subprocess.check_output(["kubectl","-n",ns,*args],text=True)
dep=json.loads(k("get","deploy","identity-api","-o","json"))
env={e["name"]:e for e in dep["spec"]["template"]["spec"]["containers"][0]["env"]}
expected={"POD_NAME":("fieldRef","metadata.name"),"POD_NAMESPACE":("fieldRef","metadata.namespace"),"NODE_NAME":("fieldRef","spec.nodeName"),"CPU_REQUEST":("resourceFieldRef","requests.cpu")}
for key,(kind,path) in expected.items():
    assert env[key]["valueFrom"][kind]["fieldPath" if kind=="fieldRef" else "resource"]==path,(key,"incorrect source")
assert env["CPU_REQUEST"]["valueFrom"]["resourceFieldRef"]["containerName"]=="api"
pods=json.loads(k("get","pods","-l","app=identity-api","-o","json"))["items"]
assert len(pods)==2
for pod in pods:
    name=pod["metadata"]["name"]
    assert pod["status"]["phase"]=="Running"
    body=k("exec",name,"-c","api","--","python","-c","import urllib.request;print(urllib.request.urlopen('http://127.0.0.1:8080/identity',timeout=5).read().decode())")
    pairs=dict(line.split("=",1) for line in body.strip().splitlines())
    assert pairs["pod"]==name,(name,pairs)
    assert pairs["namespace"]==ns
    assert pairs["node"]==pod["spec"]["nodeName"]
    assert pairs["cpu_request"]=="50",(name,pairs)
    assert "team=\"platform\"" in pairs["labels"],pairs
print("PASS: 2 pods, fieldRef, resourceFieldRef, HTTP identity, DownwardAPI labels")
PY
