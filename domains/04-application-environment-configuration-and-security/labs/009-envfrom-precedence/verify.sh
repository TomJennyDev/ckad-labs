#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-d4-009 rollout status deploy/checkout-api --timeout=120s >/dev/null
python3 - <<'PY'
import json,subprocess
ns="ckad-d4-009"
def obj(*args):return json.loads(subprocess.check_output(["kubectl","-n",ns,*args,"-o","json"],text=True))
def check(ok,msg):
 if not ok:raise SystemExit("FAIL: "+msg)
d=obj("get","deploy","checkout-api")
check(d["spec"]["replicas"]==2 and d["status"].get("readyReplicas")==2,"2/2 Ready")
c=d["spec"]["template"]["spec"]["containers"][0]
check([x["configMapRef"]["name"] for x in c["envFrom"]]==["checkout-defaults","checkout-overrides"],"envFrom order")
e={x["name"]:x for x in c["env"]}
check(e.get("APP_MODE",{}).get("value")=="production","explicit APP_MODE")
check(e.get("API_KEY",{}).get("valueFrom",{}).get("secretKeyRef",{}).get("name")=="checkout-credentials","API_KEY secret reference")
check("value" not in e["API_KEY"],"secret literal prohibited")
pods=obj("get","pods","-l","app=checkout-api")["items"]
check(len(pods)==2,"pod count")
for p in pods:
 name=p["metadata"]["name"]
 raw=subprocess.check_output(["kubectl","-n",ns,"exec",name,"--","python","-c","import os,json;print(json.dumps({k:os.getenv(k) for k in ['APP_MODE','LOG_LEVEL','PORT','FEATURE_FLAG','API_KEY']}))"],text=True)
 v=json.loads(raw)
 for k,expected in {"APP_MODE":"production","LOG_LEVEL":"debug","PORT":"8080","FEATURE_FLAG":"enabled"}.items():check(v[k]==expected,k+" mismatch in "+name)
 check(bool(v["API_KEY"]),"secret missing in "+name)
print("PASS: live Deployment, two Pods and effective env")
PY
