#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-013
fail(){ echo "FAIL: $*" >&2; exit 1; }
kubectl get ns "$NS" >/dev/null || fail "namespace missing"
kubectl -n "$NS" wait --for=condition=Ready pod/ledger-api --timeout=90s >/dev/null || fail "pod not ready"
json="$(kubectl -n "$NS" get pod ledger-api -o json)"
printf '%s' "$json" | python3 -c 'import json,sys; p=json.load(sys.stdin)["spec"]; s=p["securityContext"]; assert s["runAsNonRoot"] is True and s["runAsUser"]==10001 and s["fsGroup"]==2000; assert any(v["name"]=="shared" and "emptyDir" in v for v in p["volumes"])' || fail "securityContext/volume invalid"
actual="$(kubectl -n "$NS" exec ledger-api -c reader -- sh -c 'id -u; id -G; cat /shared/ledger.txt; stat -c %a /shared/ledger.txt')"
echo "$actual"
echo "$actual" | grep -qx '10001' || fail "wrong UID"
echo "$actual" | grep -Eq '(^| )2000( |$)' || fail "missing fsGroup membership"
echo "$actual" | grep -qx 'invoice=paid' || fail "cannot read shared file"
echo "$actual" | grep -qx '640' || fail "incorrect file mode"
echo "PASS D4-013: runtime identity, group and read verified"
