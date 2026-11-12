#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"

NS="${NS:-ckad-d1-004}"
eq "$(k -n "$NS" get pod orders -o jsonpath='{.spec.containers[0].name}' 2>/dev/null || true)" "producer" "Producer"
eq "$(k -n "$NS" get pod orders -o jsonpath='{.spec.containers[1].name}' 2>/dev/null || true)" "log-agent" "Sidecar"
eq "$(k -n "$NS" get pod orders -o jsonpath='{.spec.volumes[0].name}' 2>/dev/null || true)" "logs" "Shared emptyDir"
ok "Pod Ready" k -n "$NS" wait --for=condition=Ready pod/orders --timeout=120s
seen=""
for attempt in 1 2 3 4 5; do
  seen="$(k -n "$NS" logs pod/orders -c log-agent --tail=20 2>/dev/null || true)"
  if [[ "$seen" == *ORDER_CREATED* ]]; then break; fi
  sleep 2
done
if [[ "$seen" == *ORDER_CREATED* ]]; then
  echo "PASS sidecar exports event"
else
  echo "FAIL sidecar missing event"
  fails=$((fails+1))
fi
finish
