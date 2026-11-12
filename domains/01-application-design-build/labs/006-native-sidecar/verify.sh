#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"
NS="${NS:-ckad-d1-006}"

eq "$(k -n "$NS" get job invoice-batch -o jsonpath='{.spec.template.spec.initContainers[0].name}' 2>/dev/null || true)" "telemetry-agent" "Native sidecar placed in initContainers"
eq "$(k -n "$NS" get job invoice-batch -o jsonpath='{.spec.template.spec.initContainers[0].restartPolicy}' 2>/dev/null || true)" "Always" "Native sidecar restartPolicy Always"
eq "$(k -n "$NS" get job invoice-batch -o jsonpath='{.spec.template.spec.containers[0].name}' 2>/dev/null || true)" "invoice-worker" "Main worker container"
eq "$(k -n "$NS" get job invoice-batch -o jsonpath='{.spec.template.spec.restartPolicy}' 2>/dev/null || true)" "Never" "Job Pod restartPolicy"
eq "$(k -n "$NS" get job invoice-batch -o jsonpath='{.spec.template.spec.initContainers[0].startupProbe.exec.command[0]}' 2>/dev/null || true)" "sh" "Sidecar startupProbe configured"
ok "Job completes despite long-running native sidecar" k -n "$NS" wait --for=condition=complete job/invoice-batch --timeout=120s
eq "$(k -n "$NS" get job invoice-batch -o jsonpath='{.status.succeeded}' 2>/dev/null || true)" "1" "Exactly one successful Pod"
logs="$(k -n "$NS" logs job/invoice-batch -c invoice-worker 2>/dev/null || true)"
if [[ "$logs" == *invoice-complete* ]]; then echo "PASS invoice completed in worker logs"
else echo "FAIL worker log lacks invoice-complete"; fails=$((fails+1)); fi
sidecar_logs="$(k -n "$NS" logs job/invoice-batch -c telemetry-agent 2>/dev/null || true)"
if [[ "$sidecar_logs" == *sidecar-started* ]]; then echo "PASS sidecar started before worker"
else echo "FAIL sidecar log lacks startup marker"; fails=$((fails+1)); fi
finish

