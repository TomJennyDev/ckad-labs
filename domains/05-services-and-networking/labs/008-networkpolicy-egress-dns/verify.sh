#!/usr/bin/env bash
set -euo pipefail
n=ckad-d5-008
fail(){ echo "FAIL: $*" >&2; exit 1; }
command -v kubectl >/dev/null || fail "kubectl missing"
command -v python3 >/dev/null || fail "python3 missing"
kubectl -n "$n" rollout status deployment/pricing-api --timeout=120s >/dev/null || fail "pricing-api not Ready"
for p in checkout-worker blocked-worker; do
  kubectl -n "$n" wait --for=condition=Ready pod/"$p" --timeout=120s >/dev/null || fail "$p not Ready"
done
kubectl -n "$n" get netpol checkout-egress -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]
assert s["podSelector"]=={"matchLabels":{"app":"checkout-worker"}}, "source selector"
assert set(s["policyTypes"])=={"Egress"}, "policyTypes"
assert len(s.get("egress",[]))==2, "exactly two egress rules"
def norm(rule):
    tos=rule.get("to",[])
    ports=rule.get("ports",[])
    assert len(tos)==1 and ports, "single peer and explicit ports"
    return tos[0], {(p.get("protocol","TCP"),p.get("port")) for p in ports}
rules=[norm(r) for r in s["egress"]]
dns=({"namespaceSelector":{"matchLabels":{"kubernetes.io/metadata.name":"kube-system"}},"podSelector":{"matchLabels":{"k8s-app":"kube-dns"}}},{("UDP",53),("TCP",53)})
api=({"podSelector":{"matchLabels":{"app":"pricing-api"}}},{("TCP",5678)})
assert dns in rules and api in rules, "least-privilege destinations/ports"
' || fail "incorrect or overbroad checkout-egress"
kubectl -n "$n" get netpol blocked-egress -o json | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]
assert s["podSelector"]=={"matchLabels":{"app":"blocked-worker"}}
assert set(s["policyTypes"])=={"Egress"} and not s.get("egress",[])
' || fail "blocked-worker default deny changed"
kubectl -n kube-system get pods -l k8s-app=kube-dns -o json | python3 -c '
import json,sys
items=json.load(sys.stdin)["items"]
assert items, "CoreDNS selector has no pods"
assert any(x.get("status",{}).get("phase")=="Running" for x in items)
' || fail "CoreDNS label/health prerequisite not met"
# Kubernetes DNS and real HTTP must work; use bounded timeouts.
kubectl -n "$n" exec checkout-worker -- curl --noproxy '*' -fsS --retry 2 --retry-delay 1 --connect-timeout 3 --max-time 8 http://pricing-api:80 | grep -qx 'pricing-ok' || fail "checkout HTTP/DNS not working"
# A deny must fail even with DNS cache: connect to service ClusterIP directly.
ip=$(kubectl -n "$n" get svc pricing-api -o jsonpath='{.spec.clusterIP}')
[ -n "$ip" ] || fail "Service ClusterIP missing"
if kubectl -n "$n" exec blocked-worker -- curl --noproxy '*' -fsS --connect-timeout 2 --max-time 4 "http://$ip:80" >/dev/null 2>&1; then
  fail "blocked-worker can access API: CNI may not enforce NetworkPolicy"
fi
echo "PASS: exact egress policy, checkout DNS/HTTP succeeds, blocked-worker HTTP denied"
