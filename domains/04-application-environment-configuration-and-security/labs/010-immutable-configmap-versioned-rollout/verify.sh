#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-010
fail(){ echo "FAIL: $*" >&2; exit 1; }
kubectl get namespace "$NS" >/dev/null || fail "namespace missing"
kubectl -n "$NS" get cm catalog-config-v1 catalog-config-v2 >/dev/null || fail "configmaps missing"
kubectl -n "$NS" get deployment catalog-api >/dev/null || fail "deployment missing"
kubectl -n "$NS" rollout status deployment/catalog-api --timeout=180s >/dev/null || fail "rollout not complete"
python3 - "$NS" <<'PY'
import json,subprocess,sys
ns=sys.argv[1]
def get(*args):
    return json.loads(subprocess.check_output(['kubectl','-n',ns,'get',*args,'-o','json'],text=True))
def assert_(ok,msg):
    if not ok: raise SystemExit('FAIL: '+msg)
v1=get('cm','catalog-config-v1'); v2=get('cm','catalog-config-v2')
assert_(v1.get('immutable') is True and v1['data']['CATALOG_VERSION']=='v1','v1 changed')
assert_(v2.get('immutable') is True and v2['data']['CATALOG_VERSION']=='v2','v2 invalid')
d=get('deployment','catalog-api')
assert_(d['spec']['replicas']==2,'replicas must remain 2')
s=d['spec']['strategy']['rollingUpdate']
assert_(str(s['maxUnavailable']) in ('0','0%'),'maxUnavailable must be 0')
assert_(d['status'].get('observedGeneration',0)>=d['metadata']['generation'],'controller not observed')
assert_(all(d['status'].get(k,0)==2 for k in ('replicas','updatedReplicas','readyReplicas','availableReplicas')),'not 2/2 new ready available')
env=d['spec']['template']['spec']['containers'][0]['env']
entry=next((e for e in env if e['name']=='CATALOG_VERSION'),None)
assert_(entry is not None and 'value' not in entry and entry.get('valueFrom',{}).get('configMapKeyRef')=={'name':'catalog-config-v2','key':'CATALOG_VERSION'},'must use configMapKeyRef v2')
pods=get('pods','-l','app=catalog-api')['items']
assert_(len(pods)==2,'must have exactly 2 matching pods')
for p in pods:
    name=p['metadata']['name']
    assert_(p['status']['phase']=='Running' and all(c['ready'] for c in p['status']['containerStatuses']),name+' not ready')
    response=subprocess.check_output(['kubectl','-n',ns,'exec',name,'--','python','-c',"import urllib.request;print(urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=5).read().decode())"],text=True).strip()
    assert_(response=='version=v2',name+' HTTP response '+response)
print('PASS: immutable ConfigMaps, reference, 2/2 rollout and per-Pod HTTP v2')
PY
