#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib/common.sh"
source "$ROOT/lib/assert.sh"
eq "$(k -n "$NS" get job report -o jsonpath='{.spec.completions}' 2>/dev/null || true)" 2 "completions"
eq "$(k -n "$NS" get job report -o jsonpath='{.spec.parallelism}' 2>/dev/null || true)" 1 "parallelism"
ok "Job completed" k -n "$NS" wait job/report --for=condition=complete --timeout=90s
eq "$(k -n "$NS" get cronjob nightly -o jsonpath='{.spec.schedule}' 2>/dev/null || true)" "*/5 * * * *" "cron schedule"
eq "$(k -n "$NS" get cronjob nightly -o jsonpath='{.spec.concurrencyPolicy}' 2>/dev/null || true)" Forbid "concurrency policy"
eq "$(k -n "$NS" get cronjob nightly -o jsonpath='{.spec.suspend}' 2>/dev/null || true)" true "suspended"
finish
