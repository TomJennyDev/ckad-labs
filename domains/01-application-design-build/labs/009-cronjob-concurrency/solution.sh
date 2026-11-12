#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d1-009}"
D="$(cd "$(dirname "$0")" && pwd)"
ensure_owner "$NS"
k -n "$NS" apply -f "$D/solution.yaml"
if ! k -n "$NS" get job ledger-manual-check >/dev/null 2>&1; then
  k -n "$NS" create job ledger-manual-check --from=cronjob/nightly-ledger
fi
k -n "$NS" wait --for=condition=complete job/ledger-manual-check --timeout=120s
