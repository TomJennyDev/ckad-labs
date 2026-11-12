#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../../lib/common.sh"
source "$ROOT/lib/assert.sh"
eq "$(k -n "$NS" get pod web -o jsonpath='{.metadata.labels.app}' 2>/dev/null || true)" web "app label"
eq "$(k -n "$NS" get pod web -o jsonpath='{.metadata.labels.tier}' 2>/dev/null || true)" frontend "tier label"
eq "$(k -n "$NS" get pod web -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || true)" nginx:1.27 "image"
ok "Pod Ready" k -n "$NS" wait --for=condition=Ready pod/web --timeout=60s
finish
