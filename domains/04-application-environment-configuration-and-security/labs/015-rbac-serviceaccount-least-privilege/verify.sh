#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-015
fail(){ echo "FAIL: $*" >&2; exit 1; }
kubectl -n "$NS" wait --for=condition=Ready pod/audit-client --timeout=180s >/dev/null || fail "client not ready"
kubectl -n "$NS" get role audit-reader -o json | python3 -c '
import json,sys
r=json.load(sys.stdin)["rules"]
assert len(r)==1, "unexpected extra rules"
assert set(r[0]["apiGroups"])=={""}
assert set(r[0]["resources"])=={"configmaps"}
assert set(r[0]["verbs"])=={"get","list"}
' || fail "Role not least-privilege"
kubectl -n "$NS" get rolebinding audit-reader -o json | python3 -c '
import json,sys
b=json.load(sys.stdin)
assert b["roleRef"]=={"apiGroup":"rbac.authorization.k8s.io","kind":"Role","name":"audit-reader"}
assert b["subjects"]==[{"kind":"ServiceAccount","name":"audit-reader","namespace":"ckad-d4-015"}]
' || fail "RoleBinding incorrect"
test "$(kubectl -n "$NS" get pod audit-client -o jsonpath='{.spec.serviceAccountName}')" = audit-reader || fail "wrong identity"
run(){ kubectl -n "$NS" exec audit-client -- kubectl -n "$NS" "$@" 2>&1; }
run get configmap audit-config >/dev/null || fail "in-pod ConfigMap get denied"
run get configmaps >/dev/null || fail "in-pod ConfigMap list denied"
if run get secret confidential >/dev/null; then fail "Secret unexpectedly accessible"; fi
if run delete configmap audit-config --dry-run=server >/dev/null; then fail "write unexpectedly allowed"; fi
if run get pods >/dev/null; then fail "pods unexpectedly accessible"; fi
if run get configmap audit-config -n default >/dev/null; then fail "cross-namespace access"; fi
echo "PASS D4-015: real ServiceAccount identity has only namespaced ConfigMap read permissions"
