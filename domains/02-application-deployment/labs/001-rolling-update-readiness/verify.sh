#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-001}"
ensure_cluster
ensure_owner "$NS"
fails=0
check() { local title="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS $title"; else echo "FAIL $title"; fails=$((fails+1)); fi; }
field() { k -n "$NS" get "$1" -o "jsonpath=$2" 2>/dev/null || true; }
eq() { [[ "$1" == "$2" ]]; }
check "3 desired replicas" eq "$(field deploy/checkout '{.spec.replicas}')" "3"
check "nginx:1.29 release" eq "$(field deploy/checkout '{.spec.template.spec.containers[0].image}')" "nginx:1.29"
check "RollingUpdate" eq "$(field deploy/checkout '{.spec.strategy.type}')" "RollingUpdate"
check "maxSurge=1" eq "$(field deploy/checkout '{.spec.strategy.rollingUpdate.maxSurge}')" "1"
check "maxUnavailable=0" eq "$(field deploy/checkout '{.spec.strategy.rollingUpdate.maxUnavailable}')" "0"
check "minReadySeconds=2" eq "$(field deploy/checkout '{.spec.minReadySeconds}')" "2"
check "readiness HTTP path" eq "$(field deploy/checkout '{.spec.template.spec.containers[0].readinessProbe.httpGet.path}')" "/"
check "readiness named port" eq "$(field deploy/checkout '{.spec.template.spec.containers[0].readinessProbe.httpGet.port}')" "http"
check "release label v2" eq "$(field deploy/checkout '{.spec.template.metadata.labels.release}')" "v2"
check "rollout completed" k -n "$NS" rollout status deployment/checkout --timeout=90s
check "3 available replicas" eq "$(field deploy/checkout '{.status.availableReplicas}')" "3"
check "service selector unchanged" eq "$(field svc/checkout '{.spec.selector.app}')" "checkout"
check "service port" eq "$(field svc/checkout '{.spec.ports[0].port}')" "80"
check "EndpointSlice has ready endpoints" bash -c '
  kubectl --context kind-ckad-labs -n "$1" get endpointslices -l kubernetes.io/service-name=checkout -o json |
  python3 -c "import json,sys; d=json.load(sys.stdin); a=[e for s in d.get(\"items\",[]) for e in s.get(\"endpoints\",[]) if e.get(\"conditions\",{}).get(\"ready\") is True]; sys.exit(0 if len(a)>=3 else 1)"
' _ "$NS"
echo "Assertions failed: $fails"
(( fails == 0 ))
