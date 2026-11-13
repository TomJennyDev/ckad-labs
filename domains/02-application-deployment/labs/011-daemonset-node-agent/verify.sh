#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d2-011
fail() { echo "FAIL: $*" >&2; exit 1; }
command -v kubectl >/dev/null || fail "kubectl missing"
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "namespace missing"
kubectl -n "$NS" get daemonset node-agent >/dev/null 2>&1 || fail "DaemonSet missing"
json=$(kubectl -n "$NS" get daemonset node-agent -o json)
python3 -c '
import json,sys
d=json.load(sys.stdin)
s=d["spec"]; t=s["template"]; st=d.get("status",{})
assert s["updateStrategy"]["type"]=="RollingUpdate", "strategy"
assert s["updateStrategy"]["rollingUpdate"]["maxUnavailable"]==1, "maxUnavailable"
assert t["metadata"]["labels"]["release"]=="v2", "release"
c=t["spec"]["containers"][0]
assert c["name"]=="agent" and c["image"]=="busybox:1.36", "container"
assert "agent-v2" in " ".join(c["command"]), "command"
assert any(e.get("name")=="NODE_NAME" and e.get("valueFrom",{}).get("fieldRef",{}).get("fieldPath")=="spec.nodeName" for e in c.get("env",[])), "node env"
assert any(x.get("key")=="node-role.kubernetes.io/control-plane" and x.get("effect")=="NoSchedule" and x.get("operator")=="Exists" for x in t["spec"].get("tolerations",[])), "control-plane toleration"
n=st.get("desiredNumberScheduled",0)
assert n>0, "no eligible nodes"
assert st.get("observedGeneration",0)>=d["metadata"]["generation"], "controller not observed"
assert st.get("updatedNumberScheduled")==n, "not all updated"
assert st.get("numberReady")==n and st.get("numberAvailable")==n, "not ready"
assert st.get("numberMisscheduled",0)==0, "misscheduled"
print("PASS: desired, updated, ready, available =",n)
' <<<"$json" || fail "DaemonSet spec/status incorrect"
nodes=$(kubectl -n "$NS" get pods -l app=node-agent -o json | python3 -c '
import json,sys
p=json.load(sys.stdin)["items"]
assert p, "no pods"
nodes=[x["spec"]["nodeName"] for x in p if x["status"].get("phase")=="Running" and all(y.get("ready") for y in x["status"].get("containerStatuses",[]))]
assert len(nodes)==len(set(nodes)), "duplicate node"
assert len(nodes)==len(p), "unready pod"
print(" ".join(nodes))
') || fail "pods not healthy or duplicate"
echo "PASS: unique running agent on nodes: $nodes"
pod=$(kubectl -n "$NS" get pods -l app=node-agent -o jsonpath='{.items[0].metadata.name}')
kubectl -n "$NS" logs "$pod" --tail=20 | grep -q 'agent-v2 node=' || fail "v2 runtime logs missing"
echo "PASS D2-011: live DaemonSet rollout and runtime logs verified"
