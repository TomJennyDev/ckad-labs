#!/usr/bin/env bash
set -euo pipefail
NS="${NS:-ckad-d2-009}"
python3 - "$NS" <<'PY'
import json,subprocess,sys
ns=sys.argv[1]
def k(*args,timeout=35):
    try:
        return subprocess.run(["kubectl","--context","kind-ckad-labs","-n",ns,*args],capture_output=True,text=True,timeout=timeout)
    except (OSError,subprocess.TimeoutExpired):
        return None
def get(*args):
    r=k("get",*args,"-o","json")
    if r and r.returncode==0:
        try: return json.loads(r.stdout)
        except ValueError: pass
    return {}
checks=[]
def check(name,ok): checks.append((name,bool(ok)))
n=get("namespace",ns)
check("Namespace owned by ckad-labs",n.get("metadata",{}).get("labels",{}).get("app.kubernetes.io/managed-by")=="ckad-labs")
d=get("deployment","checkout")
spec=d.get("spec",{})
status=d.get("status",{})
check("Deployment desired replicas 3",spec.get("replicas")==3)
check("Deployment reconciled and all replicas available",status.get("observedGeneration",0)>=d.get("metadata",{}).get("generation",1) and status.get("readyReplicas")==3 and status.get("availableReplicas")==3)
pdb=get("pdb","checkout-availability")
ps=pdb.get("spec",{})
check("policy/v1 PDB minAvailable=2",pdb.get("apiVersion")=="policy/v1" and ps.get("minAvailable")==2 and "maxUnavailable" not in ps)
check("PDB selector exactly checkout pods",ps.get("selector",{}).get("matchLabels")=={"app":"checkout"})
pstatus=pdb.get("status",{})
check("PDB controller observed generation",pstatus.get("observedGeneration",0)>=pdb.get("metadata",{}).get("generation",1))
check("PDB counts 3 healthy and 2 desired",pstatus.get("currentHealthy")==3 and pstatus.get("desiredHealthy")==2 and pstatus.get("expectedPods")==3)
check("PDB allows exactly one voluntary disruption",pstatus.get("disruptionsAllowed")==1)
pods=get("pods","-l","app=checkout").get("items",[])
ready=lambda pod: any(c.get("type")=="Ready" and c.get("status")=="True" for c in pod.get("status",{}).get("conditions",[]))
check("Three real Ready checkout pods",len(pods)==3 and all(ready(p) for p in pods))
svc=get("service","checkout")
check("Service selector and port",svc.get("spec",{}).get("selector")=={"app":"checkout"} and any(x.get("port")==80 for x in svc.get("spec",{}).get("ports",[])))
eps=get("endpointslices","-l","kubernetes.io/service-name=checkout").get("items",[])
endpoints=[e for sl in eps for e in sl.get("endpoints",[]) if e.get("conditions",{}).get("ready") is True]
check("Three ready Service endpoints",len(endpoints)==3)
if pods:
    pod=pods[0]["metadata"]["name"]
    r=k("exec",pod,"-c","web","--","wget","-qO-","http://checkout/",timeout=30)
    check("Live HTTP through Service DNS",r is not None and r.returncode==0 and "Welcome to nginx" in r.stdout)
else: check("Live HTTP through Service DNS",False)
for name,ok in checks: print(("PASS" if ok else "FAIL"),name)
print(f"Score: {sum(ok for _,ok in checks)}/{len(checks)}")
sys.exit(0 if all(ok for _,ok in checks) else 1)
PY
