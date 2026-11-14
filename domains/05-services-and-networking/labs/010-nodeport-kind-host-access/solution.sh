#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-d5-010 patch service shipping-public --type=merge -p '{"spec":{"ports":[{"name":"http","protocol":"TCP","port":80,"targetPort":"http","nodePort":30080}]}}'
echo "NodePort targetPort fixed; run bash verify.sh"
