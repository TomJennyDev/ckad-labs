#!/usr/bin/env bash
set -uo pipefail
NS=ckad-d3-008
score=0
total=7
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS: $label"; score=$((score+1)); else echo "FAIL: $label"; fi; }
check "namespace" kubectl get ns "$NS"
check "deployment available" kubectl -n "$NS" wait --for=condition=available deployment/ledger-api --timeout=15s
check "service exists" kubectl -n "$NS" get service ledger-api
pod=$(kubectl -n "$NS" get pods -l app=ledger-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
check "pod ready" kubectl -n "$NS" wait --for=condition=Ready "pod/$pod" --timeout=15s
check "ephemeral debugger attached" bash -c 'kubectl -n "$1" get pod "$2" -o jsonpath="{.spec.ephemeralContainers[*].name}" | grep -qw debugger' _ "$NS" "$pod"
check "debugger terminated successfully" bash -c 'kubectl -n "$1" get pod "$2" -o jsonpath="{.status.ephemeralContainerStatuses[?(@.name==\"debugger\")].state.terminated.exitCode}" | grep -qx 0' _ "$NS" "$pod"
check "in-cluster HTTP from ephemeral debugger" bash -c 'kubectl -n "$1" logs "$2" -c debugger | grep -q "HTTP_OK"' _ "$NS" "$pod"
echo "SCORE $score/$total"
[ "$score" -eq "$total" ]
