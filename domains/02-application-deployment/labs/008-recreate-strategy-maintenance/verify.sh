#!/usr/bin/env bash
set -euo pipefail
NS="${NS:-ckad-d2-008}"
python3 - "$NS" <<'PY'
import json,subprocess,sys
ns=sys.argv[1]
def kub(*args):
 return subprocess.run(["kubectl","--context","kind-ckad-labs","-n",ns,*args],capture_output=True,text=True,timeout=30)
def obj(*args):
 p=kub(*args,"-o","json")
 return json.loads(p.stdout) if p.returncode==0 else {}
checks=[]
def check(label,ok): checks.append((label,bool(ok)))
n=kub("get","ns",ns,"-o","json")
owned=False
if n.returncode==0:
 owned=json.loads(n.stdout).get("metadata",{}).get("labels",{}).get("app.kubernetes.io/managed-by")=="ckad-labs"
check("Namespace isolated and owned",owned)
d=obj("get","deployment","ledger")
s=d.get("spec",{}); t=s.get("template",{})
check("Deployment uses Recreate",s.get("strategy",{}).get("type")=="Recreate" and "rollingUpdate" not in s.get("strategy",{}))
check("Two replicas and v2 template",s.get("replicas")==2 and t.get("metadata",{}).get("labels",{}).get("version")=="v2")
containers=t.get("spec",{}).get("containers",[])
web=next((c for c in containers if c.get("name")=="web"),{})
check("Nginx image and readiness",web.get("image")=="nginx:1.27-alpine" and web.get("readinessProbe",{}).get("httpGet",{}).get("path")=="/")
check("Resource requests and limits",web.get("resources",{}).get("requests",{}).get("memory")=="16Mi" and web.get("resources",{}).get("limits",{}).get("memory")=="64Mi")
status=d.get("status",{})
check("Observed generation and 2 ready",status.get("observedGeneration",0)>=d.get("metadata",{}).get("generation",1) and status.get("readyReplicas")==2 and status.get("updatedReplicas")==2)
svc=obj("get","service","ledger")
check("Service selector and port",svc.get("spec",{}).get("selector")=={"app":"ledger"} and any(p.get("port")==80 for p in svc.get("spec",{}).get("ports",[])))
pods=obj("get","pods","-l","app=ledger").get("items",[])
check("Only v2 ready pods",len(pods)==2 and all(p.get("metadata",{}).get("labels",{}).get("version")=="v2" and any(c.get("type")=="Ready" and c.get("status")=="True" for c in p.get("status",{}).get("conditions",[])) for p in pods))
eps=obj("get","endpointslices","-l","kubernetes.io/service-name=ledger").get("items",[])
ready=[e for sl in eps for e in sl.get("endpoints",[]) if e.get("conditions",{}).get("ready") is True]
check("EndpointSlice has two ready backends",len(ready)==2)
if pods:
 p=kub("exec",pods[0]["metadata"]["name"],"-c","web","--","wget","-qO-","http://127.0.0.1/")
 check("Real HTTP responds",p.returncode==0 and "Welcome to nginx" in p.stdout)
else: check("Real HTTP responds",False)
for label,ok in checks: print(("PASS" if ok else "FAIL"),label)
print(f"Score: {sum(ok for _,ok in checks)}/{len(checks)}")
sys.exit(0 if all(ok for _,ok in checks) else 1)
PY
