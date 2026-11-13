#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d2-006}"
ensure_cluster
ensure_owner "$NS"
command -v helm >/dev/null || fail "Install Helm first: https://helm.sh/docs/intro/install/"
helm lint "$D/chart" -f "$D/values-production.yaml"
helm upgrade --install orders "$D/chart" --kube-context "$CKAD_CONTEXT" --namespace "$NS" -f "$D/values-production.yaml" --wait --atomic --force --timeout 180s
k -n "$NS" rollout status deployment/orders --timeout=180s
