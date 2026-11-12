#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-002}"
ensure_cluster
ensure_owner "$NS"
fails=0
check() { local title="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS $title"; else echo "FAIL $title"; fails=$((fails+1)); fi; }
eq() { [[ "$1" == "$2" ]]; }
field() { k -n "$NS" get "$1" -o "jsonpath=$2" 2>/dev/null || true; }
check "restored stable image" eq "$(field deploy/payments '{.spec.template.spec.containers[0].image}')" "nginx:1.27"
check "stable Pod template label" eq "$(field deploy/payments '{.spec.template.metadata.labels.version}')" "stable"
check "two desired replicas" eq "$(field deploy/payments '{.spec.replicas}')" "2"
check "two available replicas" eq "$(field deploy/payments '{.status.availableReplicas}')" "2"
check "deployment observed latest generation" eq "$(field deploy/payments '{.metadata.generation}')" "$(field deploy/payments '{.status.observedGeneration}')"
check "rollout complete" k -n "$NS" rollout status deployment/payments --timeout=90s
check "service routes to payments" eq "$(field svc/payments '{.spec.selector.app}')" "payments"
check "ready endpoints exist" bash -c '
 kubectl --context kind-ckad-labs -n "$1" get endpointslices -l kubernetes.io/service-name=payments -o json |
 python3 -c '"'"'import json,sys; d=json.load(sys.stdin); ready=[e for s in d.get("items",[]) for e in s.get("endpoints",[]) if e.get("conditions",{}).get("ready") is True]; sys.exit(0 if len(ready)>=2 else 1)'"'"'
' _ "$NS"
check "rollback history contains failed and stable ReplicaSets" bash -c '
 kubectl --context kind-ckad-labs -n "$1" get rs -l app=payments -o json |
 python3 -c '"'"'import json,sys; d=json.load(sys.stdin); images={r["spec"]["template"]["spec"]["containers"][0]["image"] for r in d.get("items",[])}; sys.exit(0 if "nginx:1.27" in images and "nginx:missing-ckad-d2-002" in images else 1)'"'"'
' _ "$NS"
echo "Assertions failed: $fails"
(( fails == 0 ))
