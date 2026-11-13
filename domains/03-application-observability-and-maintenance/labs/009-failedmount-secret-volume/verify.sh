#!/usr/bin/env bash
set -uo pipefail
NS=ckad-d3-009
score=0; total=9
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then printf 'PASS %s\n' "$label"; score=$((score+1)); else printf 'FAIL %s\n' "$label"; fi; }
check 'correct kind context' test "$(kubectl config current-context 2>/dev/null)" = kind-ckad-labs
check 'namespace exists' kubectl get namespace "$NS"
check 'deployment available' kubectl -n "$NS" wait --for=condition=Available deployment/receipt-api --timeout=15s
check 'secret exists' kubectl -n "$NS" get secret receipt-credentials
check 'secret has token key' bash -c '[[ -n "$(kubectl -n "$1" get secret receipt-credentials -o jsonpath="{.data.token}")" ]]' _ "$NS"
check 'secret is mounted non-optional' bash -c '[[ "$(kubectl -n "$1" get deploy receipt-api -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"receipt-credentials\")].secret.secretName}")" == receipt-credentials ]] && [[ "$(kubectl -n "$1" get deploy receipt-api -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"receipt-credentials\")].secret.optional}")" != true ]]' _ "$NS"
pod=$(kubectl -n "$NS" get pod -l app=receipt-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
check 'pod ready' kubectl -n "$NS" wait --for=condition=Ready "pod/$pod" --timeout=15s
check 'secret visible inside container' kubectl -n "$NS" exec "$pod" -c web -- test -s /etc/receipt/credentials/token
check 'service HTTP 200 from in-cluster probe' kubectl -n "$NS" run "probe-$(date +%s)-$$" --restart=Never --rm -i --image=busybox:1.36 --command -- wget -q -T 10 -O /dev/null http://receipt-api.ckad-d3-009.svc.cluster.local/
echo "SCORE $score/$total"
[[ "$score" -eq "$total" ]]
