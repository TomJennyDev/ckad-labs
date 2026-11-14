#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS=ckad-d5-004
# Immutable field: delete and recreate StatefulSet controller; leave Service intact.
kubectl -n "$NS" delete sts ledger --cascade=orphan --wait=true
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata: {name: ledger, namespace: ckad-d5-004}
spec:
  serviceName: wrong-discovery
  replicas: 2
  selector:
    matchLabels: {app: ledger}
  template:
    metadata:
      labels: {app: ledger}
    spec:
      containers:
      - name: api
        image: hashicorp/http-echo:1.0.0
        args: ["-listen=:8080", "-text=ledger-peer-ok"]
        ports: [{name: http, containerPort: 8080}]
        readinessProbe:
          tcpSocket: {port: http}
          periodSeconds: 3
YAML
kubectl -n "$NS" delete pod ledger-1 ledger-0 --ignore-not-found --wait=true
kubectl -n "$NS" rollout status sts/ledger --timeout=180s >/dev/null
kubectl -n "$NS" wait --for=condition=Ready pod/ledger-0 pod/ledger-1 --timeout=180s >/dev/null
if bash "$DIR/verify.sh" >/dev/null 2>&1; then
  echo "FAIL negative: verifier accepted incorrect serviceName" >&2
  exit 1
fi
echo "PASS negative: invalid identity rejected. Restore with bash solution.sh"
