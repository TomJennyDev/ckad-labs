#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-004
fail(){ echo "FAIL: $*" >&2; exit 1; }
ok(){ echo "PASS: $*"; }
kubectl get ns "$NS" >/dev/null || fail "namespace missing"
kubectl -n "$NS" rollout status deployment/gateway --timeout=120s >/dev/null || fail "rollout not ready"
json=$(kubectl -n "$NS" get deployment gateway -o json)
python3 -c '
import json,sys
d=json.load(sys.stdin); s=d["spec"]["template"]["spec"]; c=s["containers"][0]; sc=s.get("securityContext",{}); cc=c.get("securityContext",{})
assert sc.get("runAsNonRoot") is True
assert sc.get("runAsUser")==10001 and sc.get("runAsGroup")==10001
assert sc.get("seccompProfile",{}).get("type")=="RuntimeDefault"
assert cc.get("readOnlyRootFilesystem") is True
assert cc.get("allowPrivilegeEscalation") is False
assert "ALL" in cc.get("capabilities",{}).get("drop",[])
assert any(v.get("name")=="tmp" and "emptyDir" in v for v in s.get("volumes",[]))
assert any(m.get("name")=="tmp" and m.get("mountPath")=="/tmp" for m in c.get("volumeMounts",[]))
' <<<"$json" || fail "security policy/volume invalid"
ok "deployment security settings"
pod=$(kubectl -n "$NS" get pods -l app=gateway -o jsonpath='{.items[0].metadata.name}')
[ -n "$pod" ] || fail "pod missing"
uid=$(kubectl -n "$NS" exec "$pod" -c app -- id -u)
[ "$uid" = 10001 ] || fail "runtime UID=$uid"
ok "runtime non-root UID"
kubectl -n "$NS" exec "$pod" -c app -- sh -c 'touch /tmp/probe && rm /tmp/probe' || fail "/tmp not writable"
if kubectl -n "$NS" exec "$pod" -c app -- sh -c 'touch /root/probe' >/dev/null 2>&1; then fail "root filesystem writable"; fi
ok "writable scratch, blocked rootfs"
kubectl -n "$NS" run probe-004 --image=busybox:1.36 --restart=Never --rm -i --quiet --command -- wget -qO- -T 5 http://gateway:8080/health | grep -q 'uid=10001' || fail "service HTTP response invalid"
ok "real Service HTTP request"
echo "PASS: D4-004 all checks"
