#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib/common.sh"
source "$ROOT/lib/assert.sh"
eq "$(k -n "$NS" get cm app-config -o jsonpath='{.data.APP_MODE}' 2>/dev/null || true)" production "ConfigMap value"
nonempty "$(k -n "$NS" get secret api-secret -o jsonpath='{.data.TOKEN}' 2>/dev/null || true)" "Secret TOKEN"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.configMapKeyRef.name}' 2>/dev/null || true)" app-config "configMapKeyRef"
eq "$(k -n "$NS" get deploy api -o jsonpath='{.spec.template.spec.containers[0].env[1].valueFrom.secretKeyRef.name}' 2>/dev/null || true)" api-secret "secretKeyRef"
ok "Deployment Ready" k -n "$NS" rollout status deploy/api --timeout=60s
finish
