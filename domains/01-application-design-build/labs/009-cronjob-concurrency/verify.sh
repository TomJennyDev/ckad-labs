#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"
NS="${NS:-ckad-d1-009}"
get() { k -n "$NS" get cronjob nightly-ledger -o "jsonpath=$1" 2>/dev/null || true; }
eq "$(get '{.spec.schedule}')" "*/2 * * * *" "Schedule every two minutes"
eq "$(get '{.spec.timeZone}')" "Etc/UTC" "Explicit timezone"
eq "$(get '{.spec.concurrencyPolicy}')" "Forbid" "No concurrent scheduled jobs"
eq "$(get '{.spec.startingDeadlineSeconds}')" "45" "Missed schedule deadline"
eq "$(get '{.spec.suspend}')" "true" "Safe suspended state"
eq "$(get '{.spec.successfulJobsHistoryLimit}')" "2" "Successful history"
eq "$(get '{.spec.failedJobsHistoryLimit}')" "1" "Failed history"
eq "$(get '{.spec.jobTemplate.spec.backoffLimit}')" "1" "Job retry limit"
eq "$(get '{.spec.jobTemplate.spec.template.spec.restartPolicy}')" "Never" "Restart policy"
eq "$(get '{.spec.jobTemplate.spec.template.spec.containers[0].image}')" "busybox:1.36" "Image"
eq "$(get '{.spec.jobTemplate.spec.template.spec.containers[0].resources.requests.cpu}')" "25m" "CPU request"
eq "$(get '{.spec.jobTemplate.spec.template.spec.containers[0].resources.limits.memory}')" "64Mi" "Memory limit"
ok "Manual Job completed" k -n "$NS" wait --for=condition=complete job/ledger-manual-check --timeout=120s
eq "$(k -n "$NS" get job ledger-manual-check -o jsonpath='{.metadata.annotations.cronjob\.kubernetes\.io/instantiate}' 2>/dev/null || true)" "manual" "Created from CronJob template"
ok "Correct batch output" bash -c 'kubectl --context kind-ckad-labs -n "$1" logs job/ledger-manual-check -c ledger | grep -Fxq ledger-reconciled' _ "$NS"
finish
