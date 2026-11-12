#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib/common.sh"
source "$ROOT/lib/assert.sh"
ok "web Deployment Ready" k -n "$NS" rollout status deploy/web --timeout=90s
eq "$(k -n "$NS" get svc frontend -o jsonpath='{.spec.type}' 2>/dev/null || true)" ClusterIP "service type"
eq "$(k -n "$NS" get svc frontend -o jsonpath='{.spec.selector.app}' 2>/dev/null || true)" web "selector"
eq "$(k -n "$NS" get svc frontend -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || true)" 8080 "service port"
eq "$(k -n "$NS" get svc frontend -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null || true)" 80 "targetPort"
sleep 2
nonempty "$(k -n "$NS" get endpointslices -l kubernetes.io/service-name=frontend -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null || true)" "backend addresses"
finish
