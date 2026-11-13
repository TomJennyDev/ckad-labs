#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-006}"
ensure_cluster
ensure_owner "$NS"
export NS
python3 - <<'PY'
import json, os, subprocess, sys
ns=os.environ["NS"]
checks=[]
def check(name, result):
    checks.append((name,bool(result)))
def get(kind,name=None):
    args=["kubectl","--context","kind-ckad-labs","-n",ns,"get",kind]
    if name: args.append(name)
    return json.loads(subprocess.check_output(args+["-o","json"],text=True,stderr=subprocess.DEVNULL))
def safe(kind,name=None):
    try: return get(kind,name)
    except (subprocess.CalledProcessError,ValueError): return {}
d=safe("deployment","orders")
spec=d.get("spec",{})
status=d.get("status",{})
template=spec.get("template",{})
podspec=template.get("spec",{})
containers=podspec.get("containers",[])
c=containers[0] if containers else {}
check("Deployment orders exists",bool(d))
check("3 desired replicas",spec.get("replicas")==3)
check("3 available replicas and observed generation",status.get("availableReplicas",0)==3 and status.get("observedGeneration",0)>=d.get("metadata",{}).get("generation",1))
check("Production labels on Deployment and Pod",d.get("metadata",{}).get("labels",{}).get("environment")=="production" and template.get("metadata",{}).get("labels",{}).get("environment")=="production")
check("Expected image",c.get("image")=="nginx:1.27-alpine")
check("HTTP readiness probe",c.get("readinessProbe",{}).get("httpGet",{}).get("path")=="/" and c.get("readinessProbe",{}).get("httpGet",{}).get("port")=="http")
check("RollingUpdate with zero maxUnavailable",spec.get("strategy",{}).get("rollingUpdate",{}).get("maxUnavailable")==0)
check("ConfigMap mounted via envFrom",any(e.get("configMapRef",{}).get("name")=="orders-config" for e in c.get("envFrom",[])))
cm=safe("configmap","orders-config")
check("Production ConfigMap values",cm.get("data")=={"LOG_LEVEL":"warn","APP_ENV":"production"})
svc=safe("service","orders")
check("Service selector and port",svc.get("spec",{}).get("selector")=={"app":"orders"} and any(p.get("port")==80 for p in svc.get("spec",{}).get("ports",[])))
pods=safe("pods").get("items",[])
selected=[p for p in pods if p.get("metadata",{}).get("labels",{}).get("app")=="orders"]
ready=lambda p:any(x.get("type")=="Ready" and x.get("status")=="True" for x in p.get("status",{}).get("conditions",[]))
eps=safe("endpointslices").get("items",[])
endpoints=[e for sl in eps if sl.get("metadata",{}).get("labels",{}).get("kubernetes.io/service-name")=="orders" for e in sl.get("endpoints",[]) if e.get("conditions",{}).get("ready") is True]
check("3 ready Pods and 3 ready Service endpoints",len(selected)==3 and all(ready(p) for p in selected) and len(endpoints)==3)
secrets=safe("secrets").get("items",[])
check("Helm release Secret exists",any(s.get("type")=="helm.sh/release.v1" and s.get("metadata",{}).get("labels",{}).get("owner")=="helm" and s.get("metadata",{}).get("labels",{}).get("name")=="orders" and s.get("metadata",{}).get("labels",{}).get("status")=="deployed" for s in secrets))
for label,ok in checks:print(("PASS" if ok else "FAIL"),label)
print(f"Score: {sum(ok for _,ok in checks)}/{len(checks)}")
sys.exit(0 if all(ok for _,ok in checks) else 1)
PY
