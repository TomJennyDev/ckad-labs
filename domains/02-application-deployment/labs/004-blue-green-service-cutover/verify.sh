#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-004}"
ensure_cluster
ensure_owner "$NS"
export NS
python3 - <<'PY'
import json, os, subprocess, sys
ns=os.environ["NS"]
def get(kind,name=None,selector=None):
    cmd=["kubectl","--context","kind-ckad-labs","-n",ns,"get",kind]
    if name: cmd.append(name)
    if selector: cmd.extend(["-l",selector])
    cmd.extend(["-o","json"])
    return json.loads(subprocess.check_output(cmd,text=True))
checks=[]
def check(label,ok):
    checks.append((label,bool(ok)))
try:
    svc=get("svc","storefront")
    check("Service points to green",svc["spec"]["selector"]=={"app":"storefront","track":"green"})
    check("Service port 80",any(p["port"]==80 for p in svc["spec"]["ports"]))
    for color in ("blue","green"):
        d=get("deploy","storefront-"+color)
        check(color+" deployment replicas",d["spec"]["replicas"]==2)
        check(color+" available",d["status"].get("availableReplicas",0)==2)
        check(color+" current generation",d["status"].get("observedGeneration",0)>=d["metadata"]["generation"])
        check(color+" track labels",d["spec"]["template"]["metadata"]["labels"].get("track")==color)
    slices=get("endpointslices",selector="kubernetes.io/service-name=storefront")["items"]
    ready=[e for s in slices for e in s.get("endpoints",[]) if e.get("conditions",{}).get("ready") is True]
    green=get("pods",selector="app=storefront,track=green")["items"]
    green_ips={p["status"].get("podIP") for p in green if p["status"].get("phase")=="Running"}
    endpoint_ips={ip for e in ready for ip in e.get("addresses",[])}
    check("two green ready endpoints",len(endpoint_ips)==2 and endpoint_ips==green_ips)
    blue=get("pods",selector="app=storefront,track=blue")["items"]
    blue_ips={p["status"].get("podIP") for p in blue}
    check("blue excluded from Service",not (endpoint_ips & blue_ips))
except (subprocess.CalledProcessError,KeyError,ValueError) as exc:
    check("Kubernetes API readable",False)
    print("API error:",exc,file=sys.stderr)
for label,ok in checks:
    print(("PASS" if ok else "FAIL"),label)
print(f"Score: {sum(ok for _,ok in checks)}/{len(checks)}")
sys.exit(0 if all(ok for _,ok in checks) else 1)
PY
