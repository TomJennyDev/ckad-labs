#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
NS="${NS:-ckad-d2-008}"
K=(kubectl --context kind-ckad-labs -n "$NS")
"${K[@]}" apply -f "$DIR/solution.yaml"
"${K[@]}" rollout status deployment/ledger --timeout=180s
