#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib/common.sh"
source "$ROOT/lib/assert.sh"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}' 2>/dev/null || true)" / "startup"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)" / "readiness"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null || true)" / "liveness"
ok "Deployment Ready" k -n "$NS" rollout status deploy/api --timeout=60s
finish
