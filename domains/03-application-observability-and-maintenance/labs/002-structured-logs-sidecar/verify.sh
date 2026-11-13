#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-002
kubectl config current-context | grep -q '^kind-' || { echo 'FAIL: requires kind context'; exit 2; }
python3 - "$NS" <<'PY'
import json,subprocess,sys,time
ns=sys.argv[1]
def get(*args):
    return subprocess.check_output(["kubectl","-n",ns,*args],text=True)
def check(ok,msg):
    print(("PASS" if ok else "FAIL")+": "+msg)
    if not ok: failures.append(msg)
failures=[]
d=json.loads(get("get","deployment","payment-worker","-o","json"))
spec=d["spec"]["template"]["spec"]
cs={c["name"]:c for c in spec["containers"]}
check(d["spec"]["replicas"]==1,"exactly one replica")
check(set(cs)=={"app","log-streamer"},"app and log-streamer containers")
v={x["name"]:x for x in spec.get("volumes",[])}
check("logs" in v and "emptyDir" in v["logs"],"shared emptyDir volume")
for name in ("app","log-streamer"):
    mounts=cs.get(name,{}).get("volumeMounts",[])
    check(any(m["name"]=="logs" and m["mountPath"]=="/var/log/payment" for m in mounts),name+" shared mount")
check(d.get("status",{}).get("availableReplicas",0)==1,"deployment available")
pods=json.loads(get("get","pods","-l","app=payment-worker","-o","json"))["items"]
check(len(pods)==1 and all(c.get("ready") for c in pods[0].get("status",{}).get("containerStatuses",[])) and len(pods[0].get("status",{}).get("containerStatuses",[]))==2,"both containers Ready")
if len(pods)==1:
    pod=pods[0]["metadata"]["name"]
    deadline=time.time()+35
    good=False
    while time.time()<deadline:
        logs=get("logs",pod,"-c","log-streamer","--tail=30")
        for line in logs.splitlines():
            try:
                event=json.loads(line)
                if event.get("level")=="info" and event.get("service")=="payment-worker" and event.get("event")=="payment_processed" and isinstance(event.get("seq"),int):
                    good=True
                    break
            except json.JSONDecodeError: pass
        if good:break
        time.sleep(2)
    check(good,"actual JSON event visible via kubectl logs -c log-streamer")
else:check(False,"actual log streaming")
print(f"RESULT: {len(failures)} failure(s)")
sys.exit(1 if failures else 0)
PY
