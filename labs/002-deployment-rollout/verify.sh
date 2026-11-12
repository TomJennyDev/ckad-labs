#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib/common.sh"
source "$ROOT/lib/assert.sh"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.replicas}' 2>/dev/null || true)" 3 "replicas"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)" nginx:1.29 "new image"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null || true)" 1 "maxSurge"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null || true)" 0 "maxUnavailable"
ok "rollout completed" k -n "$NS" rollout status deploy/api --timeout=90s
finish
