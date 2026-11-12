#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"
NS="${NS:-ckad-d1-002}"
eq "$(k -n "$NS" get deploy frontend -o jsonpath='{.spec.replicas}' 2>/dev/null || true)" "2" "Deployment replicas"
ok "Deployment Ready" k -n "$NS" rollout status deploy/frontend --timeout=120s
eq "$(k -n "$NS" get job daily-report -o jsonpath='{.spec.completions}' 2>/dev/null || true)" "3" "Job completions"
eq "$(k -n "$NS" get job daily-report -o jsonpath='{.spec.parallelism}' 2>/dev/null || true)" "2" "Job parallelism"
ok "Job completed" k -n "$NS" wait --for=condition=complete job/daily-report --timeout=120s
eq "$(k -n "$NS" get cronjob hourly-report -o jsonpath='{.spec.schedule}' 2>/dev/null || true)" "0 * * * *" "Cron schedule"
eq "$(k -n "$NS" get cronjob hourly-report -o jsonpath='{.spec.concurrencyPolicy}' 2>/dev/null || true)" "Forbid" "Cron concurrency"
eq "$(k -n "$NS" get cronjob hourly-report -o jsonpath='{.spec.suspend}' 2>/dev/null || true)" "true" "Cron suspended"
finish
