#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-004
# StatefulSet spec.serviceName is immutable: recreate controller, preserving Pods temporarily.
current=$(kubectl -n "$NS" get sts ledger -o jsonpath='{.spec.serviceName}')
if [[ "$current" != "peer-discovery" ]]; then
  kubectl -n "$NS" delete sts ledger --cascade=orphan --wait=true
  cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ledger
  namespace: ckad-d5-004
spec:
  serviceName: peer-discovery
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
fi
# Orphaned Pods keep old subdomain; recreate to get the new network identity.
for name in ledger-1 ledger-0; do
  subdomain=$(kubectl -n "$NS" get pod "$name" -o jsonpath='{.spec.subdomain}' 2>/dev/null || true)
  if [[ "$subdomain" != "peer-discovery" ]]; then
    kubectl -n "$NS" delete pod "$name" --ignore-not-found --wait=true
  fi
done
kubectl -n "$NS" rollout status sts/ledger --timeout=180s
kubectl -n "$NS" wait --for=condition=Ready pod/ledger-0 pod/ledger-1 --timeout=180s
