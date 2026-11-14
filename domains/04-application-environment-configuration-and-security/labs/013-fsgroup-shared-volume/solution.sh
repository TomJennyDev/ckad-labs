#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-013
kubectl -n "$NS" get pod ledger-api >/dev/null
# Init container is immutable in an existing Pod: recreate with corrected mode.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sed 's/chmod 0600 \/shared\/ledger.txt/chmod 0640 \/shared\/ledger.txt/' "$DIR/setup.yaml" | kubectl apply --dry-run=client -f - >/dev/null
kubectl -n "$NS" delete pod ledger-api --ignore-not-found --wait=true
sed 's/chmod 0600 \/shared\/ledger.txt/chmod 0640 \/shared\/ledger.txt/' "$DIR/setup.yaml" | kubectl apply -f -
kubectl -n "$NS" wait --for=condition=Ready pod/ledger-api --timeout=120s
