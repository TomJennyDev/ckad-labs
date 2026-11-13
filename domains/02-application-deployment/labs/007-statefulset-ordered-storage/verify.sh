#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-007}"
ensure_cluster
ensure_owner "$NS"
python3 - "$CKAD_CONTEXT" "$NS" <<'PY'
import json,subprocess,sys
ctx,ns=sys.argv[1:]
checks=[]
def run(*args):
    return subprocess.run(["kubectl","--context",ctx,"-n",ns,*args],capture_output=True,text=True,timeout=25)
def obj(kind,name):
    p=run("get",kind,name,"-o","json")
    return json.loads(p.stdout) if p.returncode==0 else {}
def items(kind):
    p=run("get",kind,"-o","json")
    return json.loads(p.stdout).get("items",[]) if p.returncode==0 else []
def check(label,ok):
    checks.append((label,bool(ok)))
s=obj("service","report-shard")
st=obj("statefulset","report-shard")
spec=st.get("spec",{})
tpl=spec.get("template",{}).get("spec",{})
check("Headless Service",s.get("spec",{}).get("clusterIP")=="None")
check("Service selector",s.get("spec",{}).get("selector",{}).get("app")=="report-shard")
check("StatefulSet 3 replicas and serviceName",spec.get("replicas")==3 and spec.get("serviceName")=="report-shard")
check("OrderedReady + RollingUpdate",spec.get("podManagementPolicy","OrderedReady")=="OrderedReady" and spec.get("updateStrategy",{}).get("type","RollingUpdate")=="RollingUpdate")
check("Matching Pod selector",spec.get("selector",{}).get("matchLabels",{}).get("app")=="report-shard" and spec.get("template",{}).get("metadata",{}).get("labels",{}).get("app")=="report-shard")
vcts=spec.get("volumeClaimTemplates",[])
check("PVC template RWO 100Mi",len(vcts)==1 and vcts[0].get("metadata",{}).get("name")=="data" and "ReadWriteOnce" in vcts[0].get("spec",{}).get("accessModes",[]) and vcts[0].get("spec",{}).get("resources",{}).get("requests",{}).get("storage")=="100Mi")
init=tpl.get("initContainers",[])
web=next((c for c in tpl.get("containers",[]) if c.get("name")=="web"),{})
check("Init + nginx use shared data volume",bool(init) and any(m.get("name")=="data" and m.get("mountPath")=="/data" for m in init[0].get("volumeMounts",[])) and any(m.get("name")=="data" and m.get("mountPath")=="/usr/share/nginx/html" for m in web.get("volumeMounts",[])))
check("HTTP readiness probe",web.get("readinessProbe",{}).get("httpGet",{}).get("path")=="/")
check("StatefulSet ready 3/3",st.get("status",{}).get("readyReplicas",0)==3 and st.get("status",{}).get("observedGeneration",0)>=st.get("metadata",{}).get("generation",1))
pods={p.get("metadata",{}).get("name"):p for p in items("pods")}
names=[f"report-shard-{i}" for i in range(3)]
check("Stable Pod ordinal identities",all(n in pods and any(c.get("type")=="Ready" and c.get("status")=="True" for c in pods[n].get("status",{}).get("conditions",[])) for n in names))
pvcs={p.get("metadata",{}).get("name"):p for p in items("pvc")}
check("Three bound independent PVCs",all(f"data-{n}" in pvcs and pvcs[f"data-{n}"].get("status",{}).get("phase")=="Bound" for n in names))
eps=items("endpointslices")
ready_addresses=set()
for e in eps:
    if e.get("metadata",{}).get("labels",{}).get("kubernetes.io/service-name")=="report-shard":
        for endpoint in e.get("endpoints",[]):
            if endpoint.get("conditions",{}).get("ready") is True:
                ready_addresses.add(endpoint.get("targetRef",{}).get("name"))
check("EndpointSlice has three Ready Pods",all(n in ready_addresses for n in names))
bodies=[]
for n in names:
    p=run("exec",n,"-c","web","--","wget","-qO-","http://127.0.0.1/")
    bodies.append(p.returncode==0 and p.stdout.strip()==n)
check("Live HTTP content matches each ordinal",all(bodies))
for label,ok in checks:
    print(("PASS" if ok else "FAIL"),label)
score=sum(ok for _,ok in checks)
print(f"Score: {score}/{len(checks)}")
sys.exit(0 if score==len(checks) else 1)
PY
