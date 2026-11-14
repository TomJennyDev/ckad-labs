#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl -n ckad-d5-003 delete pod storefront --wait=true
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: storefront, namespace: ckad-d5-003}
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "sleep 86400"]
    env: [{name: CATALOG_URL, value: "http://catalog:80/"}]
YAML
kubectl -n ckad-d5-003 wait --for=condition=Ready pod/storefront --timeout=180s >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then echo "FAIL negative: invalid DNS accepted" >&2; exit 1; fi
echo "PASS negative: short DNS name rejected; restore with bash solution.sh"
