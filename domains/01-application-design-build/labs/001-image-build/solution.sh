#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
D="$(cd "$(dirname "$0")" && pwd)"
docker build -t ckad-d1-web:v1 -f "$D/Dockerfile.solution" "$D"
kind load docker-image --name ckad-labs ckad-d1-web:v1
k -n "$NS" apply -f "$D/solution.yaml"
