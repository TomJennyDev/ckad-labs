#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"
NS="${NS:-ckad-d1-008}"
get() { k -n "$NS" get job invoice-retry -o "jsonpath=$1" 2>/dev/null || true; }
eq "$(get '{.spec.completions}')" 1 "One completion"
eq "$(get '{.spec.parallelism}')" 1 "One parallel worker"
eq "$(get '{.spec.backoffLimit}')" 2 "Bounded retry budget"
eq "$(get '{.spec.activeDeadlineSeconds}')" 180 "Global deadline"
eq "$(get '{.spec.ttlSecondsAfterFinished}')" 3600 "TTL cleanup policy"
eq "$(get '{.spec.template.spec.restartPolicy}')" Never "Retry uses new Pods"
eq "$(get '{.spec.template.spec.containers[0].image}')" busybox:1.36 "Image"
ok "Job Complete" k -n "$NS" wait --for=condition=complete job/invoice-retry --timeout=120s
eq "$(get '{.status.succeeded}')" 1 "Succeeded exactly once"
ok "Marker in completed worker logs" bash -c 'kubectl --context kind-ckad-labs -n "$1" logs job/invoice-retry -c processor | grep -Fxq invoice-processed' _ "$NS"
finish

