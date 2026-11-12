#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
CKAD_CONTEXT="kind-ckad-labs"
k() { kubectl --context "$CKAD_CONTEXT" "$@"; }
fail() { echo "ERROR: $*" >&2; exit 1; }
ensure_cluster() { k cluster-info >/dev/null 2>&1 || fail "Run ./env/kind/up.sh"; }
ensure_owner() {
  local owner
  owner="$(k get ns "$1" -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}' 2>/dev/null || true)"
  [[ "$owner" == "ckad-labs" ]] || fail "Namespace $1 is not managed by ckad-labs"
}
