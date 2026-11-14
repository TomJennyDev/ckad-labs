#!/usr/bin/env bash
set -euo pipefail
kubectl apply -f - <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: checkout-egress
  namespace: ckad-d5-008
spec:
  podSelector:
    matchLabels: {app: checkout-worker}
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - {protocol: UDP, port: 53}
        - {protocol: TCP, port: 53}
    - to:
        - podSelector:
            matchLabels: {app: pricing-api}
      ports:
        - {protocol: TCP, port: 5678}
YAML
