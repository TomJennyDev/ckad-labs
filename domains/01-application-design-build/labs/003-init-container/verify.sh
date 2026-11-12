#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"

NS="${NS:-ckad-d1-003}"
eq "$(k -n "$NS" get pod bootstrap -o jsonpath='{.spec.initContainers[0].name}' 2>/dev/null || true)" "prepare" "Init container"
eq "$(k -n "$NS" get pod bootstrap -o jsonpath='{.spec.containers[0].name}' 2>/dev/null || true)" "app" "Main container"
eq "$(k -n "$NS" get pod bootstrap -o jsonpath='{.spec.volumes[0].name}' 2>/dev/null || true)" "state" "Shared volume"
ok "Pod Ready" k -n "$NS" wait --for=condition=Ready pod/bootstrap --timeout=120s
eq "$(k -n "$NS" exec bootstrap -c app -- cat /work/ready.flag 2>/dev/null || true)" "initialized" "Init handoff"
eq "$(k -n "$NS" get pod bootstrap -o jsonpath='{.status.initContainerStatuses[0].state.terminated.exitCode}' 2>/dev/null || true)" "0" "Init completed successfully"
finish
