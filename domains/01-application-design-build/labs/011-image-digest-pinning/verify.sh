#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"
NS="${NS:-ckad-d1-011}"
ensure_cluster
ensure_owner "$NS"
field() { k -n "$NS" get deployment catalog-api -o "jsonpath=$1" 2>/dev/null || true; }
image="$(field '{.spec.template.spec.containers[0].image}')"
if [[ "$image" =~ ^(docker.io/library/)?nginx@sha256:[a-f0-9]{64}$ ]]; then
  echo "PASS immutable image digest"
else
  echo "FAIL image must be nginx@sha256:<64 lowercase hex>"; fails=$((fails+1))
fi
eq "$(field '{.spec.replicas}')" "2" "two replicas"
eq "$(field '{.spec.template.metadata.labels.release}')" "digest-pinned" "release label"
eq "$(field '{.spec.template.spec.containers[0].imagePullPolicy}')" "Always" "explicit pull policy"
eq "$(field '{.spec.template.spec.containers[0].resources.requests.cpu}')" "20m" "cpu request"
eq "$(field '{.spec.template.spec.containers[0].resources.limits.memory}')" "128Mi" "memory limit"
ok "deployment rollout" k -n "$NS" rollout status deploy/catalog-api --timeout=180s
eq "$(field '{.status.readyReplicas}')" "2" "ready replicas"
pods="$(k -n "$NS" get pods -l app=catalog-api -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' 2>/dev/null || true)"
while IFS= read -r actual; do
  [[ -n "$actual" ]] || continue
  eq "$actual" "$image" "Pod spec image matches deployment"
done <<< "$pods"
if [[ -z "$pods" ]]; then echo "FAIL no selected pods"; fails=$((fails+1)); fi
# The exact resolved manifest digest must also match the known registry digest when available.
if command -v docker >/dev/null 2>&1 && docker image inspect docker.io/library/nginx:1.27 >/dev/null 2>&1; then
  known="$(docker image inspect docker.io/library/nginx:1.27 --format '{{range .RepoDigests}}{{println .}}{{end}}' | grep -E '^(.*/)?nginx@sha256:[0-9a-f]{64}$' | head -1 | sed -E 's/^.*@sha256://' || true)"
  if [[ -n "$known" ]]; then eq "${image##*@sha256:}" "$known" "registry manifest digest matches local pulled reference"; fi
fi
finish
