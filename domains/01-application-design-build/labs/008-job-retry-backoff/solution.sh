#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d1-008}"
D="$(cd "$(dirname "$0")" && pwd)"
ensure_owner "$NS"
# Job.spec.template is immutable; replace only this lab's named Job, not its namespace.
k -n "$NS" delete job invoice-retry --ignore-not-found --wait=true
k -n "$NS" apply -f "$D/solution.yaml"
k -n "$NS" wait --for=condition=complete job/invoice-retry --timeout=120s

