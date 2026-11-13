#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-003
[[ "$(kubectl config current-context)" == kind-* ]] || { echo "FAIL: kind context required"; exit 2; }
python3 - "$NS" <<'PY'
import json,subprocess,sys,time
ns=sys.argv[1]
def cmd(*a): return subprocess.check_output(["kubectl","-n",ns,*a],text=True)
def check(x,msg):
 print(("PASS" if x else "FAIL")+": "+msg)
 if not x: failures.append(msg)
failures=[]
try:
 d=json.loads(cmd("get","deployment","report-api","-o","json"))
 spec=d["spec"]["template"]["spec"]
 c=spec["containers"][0]
 check(d["spec"]["replicas"]==1,"one replica")
 check(c["name"]=="api","api container")
 check(c.get("resources",{}).get("requests",{}).get("memory")=="128Mi","request 128Mi")
 check(c.get("resources",{}).get("limits",{}).get("memory")=="192Mi","limit 192Mi")
 deadline=time.time()+90
 ready=False
 stable=False
 while time.time()<deadline:
  pods=json.loads(cmd("get","pods","-l","app=report-api","-o","json"))["items"]
  if len(pods)==1:
   p=pods[0]; statuses=p.get("status",{}).get("containerStatuses",[])
   if statuses and statuses[0].get("ready") and p.get("status",{}).get("phase")=="Running":
    first=statuses[0].get("restartCount",0)
    time.sleep(8)
    newer=json.loads(cmd("get","pod",p["metadata"]["name"],"-o","json"))["status"]["containerStatuses"][0]
    ready=True; stable=newer.get("ready",False) and newer.get("restartCount",0)==first
    break
  time.sleep(3)
 check(ready,"pod running and ready")
 check(stable,"no new container restart during observation")
 if len(pods)==1:
  logs=cmd("logs",pods[0]["metadata"]["name"],"-c","api","--tail=30")
  check("allocated 100663296" in logs,"actual 96MiB allocation observed in container logs")
 else: check(False,"allocation log")
except (subprocess.CalledProcessError,KeyError,IndexError) as e:
 check(False,"Kubernetes query: "+str(e))
print("RESULT:",len(failures),"failure(s)")
sys.exit(bool(failures))
PY
