#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" != "--confirm" ]]; then
  echo "DANGER: this removes the entire ckad-labs cluster. Usage: ./env/kind/down.sh --confirm"
  exit 1
fi
KIND_EXPERIMENTAL_PROVIDER=docker kind delete cluster --name ckad-labs
