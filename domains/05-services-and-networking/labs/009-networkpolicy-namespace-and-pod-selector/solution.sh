#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-d5-009-api apply -f - <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: billing-ingress
  namespace: ckad-d5-009-api
spec:
  podSelector:
    matchLabels: {app: billing-api}
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels: {access-tier: trusted}
          podSelector:
            matchLabels: {role: billing-client}
      ports:
        - protocol: TCP
          port: 5678
YAML
echo "Applied AND selector. Run bash verify.sh to validate actual traffic."
