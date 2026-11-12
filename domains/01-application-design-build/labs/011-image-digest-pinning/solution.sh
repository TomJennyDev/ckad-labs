#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
D="$(cd "$(dirname "$0")" && pwd)"
NS="${NS:-ckad-d1-011}"
ensure_cluster
ensure_owner "$NS"
command -v docker >/dev/null || fail "docker required to resolve real registry digest"
docker pull docker.io/library/nginx:1.27 >/dev/null
# RepoDigests is a registry MANIFEST digest, not local image config ID.
digest="$(docker image inspect docker.io/library/nginx:1.27 --format '{{range .RepoDigests}}{{println .}}{{end}}' | grep -E '^(.*/)?nginx@sha256:[0-9a-f]{64}$' | head -1 | sed -E 's/^.*@sha256://')"
[[ "$digest" =~ ^[0-9a-f]{64}$ ]] || fail "No valid registry manifest digest; do not guess"
sed "s/REPLACE_WITH_64_HEX_MANIFEST_DIGEST/$digest/g" "$D/solution.yaml" | k -n "$NS" apply -f -
k -n "$NS" rollout status deploy/catalog-api --timeout=180s
echo "Pinned registry digest sha256:$digest"
