#!/usr/bin/env bash
set -euo pipefail
K=(kubectl --context kind-ckad-labs -n ckad-d4-001)
"${K[@]}" patch configmap pricing-settings --type merge -p '{"data":{"discount.txt":"15"}}'
echo "Patched ConfigMap. Wait for kubelet volume propagation; do not restart Deployment."
