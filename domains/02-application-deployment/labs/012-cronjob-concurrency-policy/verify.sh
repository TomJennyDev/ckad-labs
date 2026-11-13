#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d2-012
command -v kubectl >/dev/null || { echo "Missing kubectl"; exit 2; }
command -v python3 >/dev/null || { echo "Missing python3"; exit 2; }
kubectl get ns "$NS" >/dev/null
CJ="$(kubectl -n "$NS" get cronjob billing-reconcile -o json)"
printf '%s' "$CJ" | python3 -c '
import json,sys
j=json.load(sys.stdin); s=j["spec"]; t=s["jobTemplate"]["spec"]; p=t["template"]["spec"]
checks={
 "schedule":s.get("schedule")=="*/5 * * * *",
 "timezone":s.get("timeZone")=="Etc/UTC",
 "concurrency":s.get("concurrencyPolicy")=="Forbid",
 "deadline":s.get("startingDeadlineSeconds")==120,
 "history":s.get("successfulJobsHistoryLimit")==2 and s.get("failedJobsHistoryLimit")==1,
 "enabled":s.get("suspend") is False,
 "job-policy":t.get("backoffLimit")==1 and t.get("activeDeadlineSeconds")==180 and t.get("ttlSecondsAfterFinished")==600,
 "pod-policy":p.get("restartPolicy")=="Never",
 "container":len(p.get("containers",[]))==1 and p["containers"][0].get("name")=="reconcile" and p["containers"][0].get("image")=="busybox:1.36",
 "command":p["containers"][0].get("command")==["/bin/sh","-c","echo reconcile-complete"],
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
if not all(checks.values()): sys.exit(1)
'
JOB="$(kubectl -n "$NS" get jobs -l ckad-lab=d2-012-manual -o json)"
printf '%s' "$JOB" | python3 -c '
import json,sys
jobs=json.load(sys.stdin)["items"]
assert jobs, "Missing labelled manual Job; run solution.sh or create job --from and label it"
ok=False
for j in jobs:
 s=j.get("status",{})
 if s.get("succeeded",0)>=1 and any(c.get("type")=="Complete" and c.get("status")=="True" for c in s.get("conditions",[])):
  ok=True
assert ok, "No successful manual Job"
print("PASS manual Job completed")
'
PODS="$(kubectl -n "$NS" get pods -l job-name=manual-reconcile -o json)"
POD="$(printf '%s' "$PODS" | python3 -c 'import json,sys; a=json.load(sys.stdin)["items"]; a=[p for p in a if p.get("status",{}).get("phase")=="Succeeded"]; assert a,"No succeeded manual Pod"; print(a[-1]["metadata"]["name"])')"
kubectl -n "$NS" logs "$POD" | grep -Fxq 'reconcile-complete'
echo "PASS Pod succeeded and real logs contain reconcile-complete"
echo "PASS D2-012"
