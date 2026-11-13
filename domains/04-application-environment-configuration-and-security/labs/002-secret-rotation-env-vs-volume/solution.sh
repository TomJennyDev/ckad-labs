#!/usr/bin/env bash
set -euo pipefail
K=(kubectl --context kind-ckad-labs -n ckad-d4-002)
"${K[@]}" patch secret billing-credentials --type=merge -p '{"stringData":{"api-key":"key-v2"}}'
echo 'Secret updated. Wait for kubelet to project volume; do not restart Pod.'
