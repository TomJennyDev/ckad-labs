#!/usr/bin/env bash
set -euo pipefail
n=ckad-d5-007
fail(){ echo "FAIL: $*" >&2; exit 1; }
kubectl -n "$n" rollout status deploy/orders --timeout=120s >/dev/null || fail "orders not ready"
for p in frontend intruder; do kubectl -n "$n" wait --for=condition=Ready pod/"$p" --timeout=120s >/dev/null || fail "$p not ready"; done
kubectl -n "$n" get networkpolicy orders-ingress -o json | python3 -c 'import json,sys;p=json.load(sys.stdin)["spec"];assert p["podSelector"]["matchLabels"]=={"app":"orders"};assert p["policyTypes"]==["Ingress"];assert len(p["ingress"])==1;r=p["ingress"][0];assert len(r["from"])==1 and r["from"][0]["podSelector"]["matchLabels"]=={"role":"frontend"};assert len(r["ports"])==1 and r["ports"][0]["port"]==5678 and r["ports"][0].get("protocol","TCP")=="TCP"' || fail "policy too broad or incorrect"
kubectl -n "$n" exec frontend -- curl -fsS --max-time 5 http://orders | grep -q orders-ok || fail "frontend denied"
if kubectl -n "$n" exec intruder -- curl -fsS --max-time 4 http://orders >/dev/null 2>&1; then fail "intruder allowed"; fi
echo "PASS: permitted and denied real HTTP traffic"
