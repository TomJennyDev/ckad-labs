#!/usr/bin/env bash
set -euo pipefail
kubectl apply -f - <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: orders-ingress, namespace: ckad-d5-007}
spec:
  podSelector: {matchLabels: {app: orders}}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector: {matchLabels: {role: frontend}}
    ports:
    - {protocol: TCP, port: 5678}
YAML
