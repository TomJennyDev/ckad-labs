#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export KIND_EXPERIMENTAL_PROVIDER=docker
for bin in docker kind kubectl; do
  command -v "$bin" >/dev/null || { echo "Missing $bin" >&2; exit 1; }
done
docker info >/dev/null || { echo "Docker Engine is not running" >&2; exit 1; }
if ! kind get clusters | grep -Fxq ckad-labs; then
  kind create cluster --name ckad-labs --config "$ROOT/env/kind/cluster.yaml" --image "kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5" --wait 120s
fi
kubectl --context kind-ckad-labs wait --for=condition=Ready nodes --all --timeout=120s
kubectl --context kind-ckad-labs get nodes -o wide
