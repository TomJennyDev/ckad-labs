#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-001
[[ "$(kubectl config current-context)" == kind-* ]] || { echo "FAIL: kind context required"; exit 1; }
kubectl get namespace "$NS" >/dev/null
DEP="$(kubectl -n "$NS" get deployment checkout-api -o json)"
SVC="$(kubectl -n "$NS" get service checkout-api -o json)"
EPS="$(kubectl -n "$NS" get endpointslice -l kubernetes.io/service-name=checkout-api -o json)"
PODS="$(kubectl -n "$NS" get pods -l app=checkout-api -o json)"
python3 - "$DEP" "$SVC" "$EPS" "$PODS" <<'PY'
import json,sys
d,s,e,p=map(json.loads,sys.argv[1:])
def check(ok,msg):
    if not ok: raise SystemExit("FAIL: "+msg)
    print("PASS: "+msg)
check(d['spec']['replicas']==2,'replicas=2')
c=d['spec']['template']['spec']['containers'][0]
check(c['image']=='registry.k8s.io/e2e-test-images/agnhost:2.53','pinned image')
for k,period,threshold in [('startupProbe',2,15),('readinessProbe',3,2),('livenessProbe',5,3)]:
    q=c.get(k,{})
    check(q.get('httpGet',{}).get('path')=='/healthz' and q['httpGet'].get('port')==8080 and q.get('periodSeconds')==period and q.get('failureThreshold')==threshold,k+' configuration')
check(d['status'].get('availableReplicas',0)==2,'two available replicas')
check(s['spec']['selector']=={'app':'checkout-api'},'service selector')
ready=sum(1 for sl in e['items'] for ep in sl.get('endpoints',[]) if ep.get('conditions',{}).get('ready') is True)
check(ready==2,'two ready EndpointSlice backends')
pods=p['items']
check(len(pods)==2 and all(any(x['type']=='Ready' and x['status']=='True' for x in pod['status'].get('conditions',[])) for pod in pods),'two ready pods')
PY
echo "PASS D3-001 (live Kubernetes API)"
