#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"
NS="${NS:-ckad-d1-001}"
eq "$(k -n "$NS" get deploy web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)" "ckad-d1-web:v1" "Image name"
eq "$(k -n "$NS" get deploy web -o jsonpath='{.spec.template.spec.containers[0].imagePullPolicy}' 2>/dev/null || true)" "Never" "Pull policy"
ok "Pod Ready" k -n "$NS" rollout status deploy/web --timeout=120s
ok "App serves expected build version" k -n "$NS" exec deploy/web -- sh -c 'wget -qO- http://127.0.0.1/ | grep -q ckad-image-ready-v1'
finish
