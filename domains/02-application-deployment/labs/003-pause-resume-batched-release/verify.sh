#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-003}"
ensure_cluster
ensure_owner "$NS"
fail=0
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS $label"; else echo "FAIL $label"; fail=$((fail+1)); fi; }
eq() { [[ "$1" == "$2" ]]; }
field() { k -n "$NS" get deploy/catalog -o "jsonpath=$1" 2>/dev/null || true; }
check "new image" eq "$(field '{.spec.template.spec.containers[0].image}')" "nginx:1.27-alpine"
check "release label" eq "$(field '{.spec.template.metadata.labels.release}')" "v2"
check "change ticket annotation" eq "$(field '{.spec.template.metadata.annotations.ckad\.dev/change-ticket}')" "CHG-203"
check "resumed" eq "$(field '{.spec.paused}')" ""
check "two desired replicas" eq "$(field '{.spec.replicas}')" "2"
check "two available replicas" eq "$(field '{.status.availableReplicas}')" "2"
check "controller observed current generation" eq "$(field '{.metadata.generation}')" "$(field '{.status.observedGeneration}')"
check "rollout complete" k -n "$NS" rollout status deployment/catalog --timeout=120s
check "service selector" bash -c '[[ "$(kubectl --context kind-ckad-labs -n "$1" get svc catalog -o jsonpath="{.spec.selector.app}")" == catalog ]]' _ "$NS"
check "two ready endpoints" bash -c 'kubectl --context kind-ckad-labs -n "$1" get endpointslices -l kubernetes.io/service-name=catalog -o json | python3 -c '\''import json,sys; d=json.load(sys.stdin); e=[x for s in d["items"] for x in s.get("endpoints",[]) if x.get("conditions",{}).get("ready") is True]; sys.exit(0 if len(e)>=2 else 1)'\''' _ "$NS"
check "stable and candidate revision templates exist" bash -c 'kubectl --context kind-ckad-labs -n "$1" get rs -l app=catalog -o json | python3 -c '\''import json,sys; d=json.load(sys.stdin); im={c["image"] for r in d["items"] for c in r["spec"]["template"]["spec"]["containers"]}; sys.exit(0 if {"nginx:1.27","nginx:1.27-alpine"}<=im else 1)'\''' _ "$NS"
echo "Failed checks: $fail"
(( fail == 0 ))
