#!/usr/bin/env bash
set -euo pipefail
NS="${NS:-ckad-d2-010}" CTX="${CTX:-kind-ckad-labs}"
python3 - "$NS" "$CTX" <<'PY'
import json, subprocess, sys
ns, ctx=sys.argv[1:]
def get(*args):
    try:
        p=subprocess.run(["kubectl","--context",ctx,"-n",ns,"get",*args,"-o","json"],capture_output=True,text=True,timeout=25)
        return json.loads(p.stdout) if p.returncode==0 else {}
    except (OSError,ValueError,subprocess.TimeoutExpired):
        return {}
checks=[]
def check(label,condition): checks.append((label,bool(condition)))
namespace=get("namespace",ns)
check("Isolated managed namespace",namespace.get("metadata",{}).get("labels",{}).get("app.kubernetes.io/managed-by")=="ckad-labs")
for track,replicas in [("stable",4),("canary",1)]:
    d=get("deployment","storefront-"+track)
    spec=d.get("spec",{})
    status=d.get("status",{})
    selector={"app":"storefront","track":track}
    check(track+" correct replica target",spec.get("replicas")==replicas)
    check(track+" selectors and template",spec.get("selector",{}).get("matchLabels")==selector and all(d.get("spec",{}).get("template",{}).get("metadata",{}).get("labels",{}).get(k)==v for k,v in selector.items()))
    check(track+" live ready and available",status.get("observedGeneration",0)>=d.get("metadata",{}).get("generation",1) and status.get("readyReplicas")==replicas and status.get("availableReplicas")==replicas)
    containers=spec.get("template",{}).get("spec",{}).get("containers",[])
    check(track+" readiness probe",len(containers)==1 and containers[0].get("readinessProbe",{}).get("httpGet",{}).get("path")=="/")
svc=get("service","storefront")
check("Service selects both tracks",svc.get("spec",{}).get("selector")=={"app":"storefront"})
check("Service HTTP port 80",any(p.get("port")==80 and p.get("targetPort")==80 for p in svc.get("spec",{}).get("ports",[])))
pods=get("pods","-l","app=storefront").get("items",[])
ready=lambda p:any(c.get("type")=="Ready" and c.get("status")=="True" for c in p.get("status",{}).get("conditions",[]))
check("Five live ready Pods with 4:1 split",len(pods)==5 and all(ready(p) for p in pods) and sum(p.get("metadata",{}).get("labels",{}).get("track")=="stable" for p in pods)==4 and sum(p.get("metadata",{}).get("labels",{}).get("track")=="canary" for p in pods)==1)
slices=get("endpointslices","-l","kubernetes.io/service-name=storefront").get("items",[])
ips={a for s in slices for e in s.get("endpoints",[]) if e.get("conditions",{}).get("ready") is True for a in e.get("addresses",[])}
pod_ips={p.get("status",{}).get("podIP") for p in pods}
check("EndpointSlice includes exactly five ready Pod IPs",len(ips)==5 and ips==pod_ips)
if pods:
    pod=pods[0].get("metadata",{}).get("name")
    try:
        r=subprocess.run(["kubectl","--context",ctx,"-n",ns,"exec",pod,"--","wget","-qO-","http://storefront/"],capture_output=True,text=True,timeout=25)
        check("Live Service DNS HTTP",r.returncode==0 and "Welcome to nginx" in r.stdout)
    except (OSError,subprocess.TimeoutExpired):
        check("Live Service DNS HTTP",False)
else: check("Live Service DNS HTTP",False)
for label,ok in checks: print(("PASS" if ok else "FAIL")+" "+label)
print("Score: %d/%d"%(sum(ok for _,ok in checks),len(checks)))
sys.exit(0 if all(ok for _,ok in checks) else 1)
PY
