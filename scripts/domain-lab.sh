#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/lib/common.sh"
BASE="$ROOT/domains/01-application-design-build/labs"
cmd="${1:-help}"
id="${2:-}"
if [[ "$cmd" == help || "$cmd" == --help ]]; then
  echo "Usage: ./ckad domain list|start|check|hint|solve|reset [D1-001...]"
  exit 0
fi
if [[ "$cmd" == list ]]; then
  for d in "$BASE"/[0-9][0-9][0-9]-*/; do
    [[ -d "$d" ]] || continue
    echo "D1-$(basename "$d" | cut -c1-3): $(head -1 "$d/README.md" | sed 's/^# //')"
  done
  exit 0
fi
[[ "$cmd" =~ ^(start|check|hint|solve|reset)$ ]] || fail "Unknown command"
[[ "$id" =~ ^D1-[0-9]{3}$ ]] || fail "Expected D1-001 etc."
num="${id#D1-}"
d="$(find "$BASE" -mindepth 1 -maxdepth 1 -type d -name "$num-*" -print -quit)"
[[ -n "$d" ]] || fail "$id not implemented"
ns="ckad-d1-$num"
if [[ "$cmd" == hint ]]; then
  echo "kubectl --context kind-ckad-labs -n $ns get all"
  echo "kubectl --context kind-ckad-labs -n $ns get events --sort-by=.lastTimestamp"
  exit 0
fi
ensure_cluster
if [[ "$cmd" == start ]]; then
  if k get ns "$ns" >/dev/null 2>&1; then ensure_owner "$ns"
  else
    k create ns "$ns"
    k label ns "$ns" app.kubernetes.io/managed-by=ckad-labs
  fi
  if grep -q '^kind:' "$d/setup.yaml"; then k -n "$ns" apply -f "$d/setup.yaml"; fi
  echo "Ready $id namespace $ns. See $d/README.md"
else
  ensure_owner "$ns"
  case "$cmd" in
    check) NS="$ns" bash "$d/verify.sh" ;;
    solve) NS="$ns" bash "$d/solution.sh" ;;
    reset) k delete ns "$ns" --wait=false ;;
  esac
fi
