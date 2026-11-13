#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-005}"
ensure_cluster
ensure_owner "$NS"
export NS
python3 - <<'PY'
import json,os,subprocess,sys
ns=os.environ["NS"]
def get(kind,name=None):
    cmd=["kubectl","--context","kind-ckad-labs","-n",ns,"get",kind]
    if name:cmd.append(name)
    return json.loads(subprocess.check_output(cmd+["-o","json"],text=True))
checks=[]
def check(label,ok):checks.append((label,bool(ok)))
try:
    d=get("deploy","inventory")
    spec=d["spec"]; st=d.get("status",{}); template=spec["template"]
    check("3 desired replicas",spec.get("replicas")==3)
    check("3 available replicas",st.get("availableReplicas",0)==3)
    check("controller observed latest generation",st.get("observedGeneration",0)>=d["metadata"]["generation"])
    check("production label on deployment",d["metadata"].get("labels",{}).get("environment")=="production")
    check("production pod label",template["metadata"].get("labels",{}).get("environment")=="production")
    check("immutable selector preserved",spec["selector"]["matchLabels"]=={"app":"inventory"})
    c=template["spec"]["containers"][0]
    check("nginx image retained",c["image"]=="nginx:1.27-alpine")
    check("readiness HTTP probe retained",c.get("readinessProbe",{}).get("httpGet",{}).get("path")=="/")
    refs=[e.get("configMapRef",{}).get("name") for e in c.get("envFrom",[])]
    check("generated configmap reference",len(refs)==1 and refs[0].startswith("inventory-settings-"))
    cms=get("configmaps")["items"]
    matched=[x for x in cms if x["metadata"]["name"] in refs]
    check("generated configmap exists",len(matched)==1)
    check("production configuration",len(matched)==1 and matched[0].get("data",{})=={"APP_MODE":"production","LOG_LEVEL":"warn"})
    svc=get("svc","inventory")
    check("service selector unchanged",svc["spec"].get("selector")=={"app":"inventory"})
    pods=get("pods")["items"]
    selected=[p for p in pods if p["metadata"].get("labels",{}).get("app")=="inventory"]
    check("3 ready production pods",len(selected)==3 and all(p["metadata"]["labels"].get("environment")=="production" and any(c.get("type")=="Ready" and c.get("status")=="True" for c in p.get("status",{}).get("conditions",[])) for p in selected))
except (subprocess.CalledProcessError,KeyError,ValueError,IndexError) as e:
    check("Kubernetes state accessible",False)
    print("ERROR",e,file=sys.stderr)
for label,ok in checks:print(("PASS" if ok else "FAIL"),label)
print(f"Score: {sum(ok for _,ok in checks)}/{len(checks)}")
sys.exit(0 if all(ok for _,ok in checks) else 1)
PY
