#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" != "--confirm" ]]; then
  echo "Usage: ./env/kind/down.sh --confirm"
  exit 1
fi
KIND_EXPERIMENTAL_PROVIDER=docker kind delete cluster --name ckad-labs
