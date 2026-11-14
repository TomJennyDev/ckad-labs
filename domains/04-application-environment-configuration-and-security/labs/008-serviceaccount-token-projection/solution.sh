#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-008
kubectl -n "$NS" patch deployment invoice-reader --type=strategic -p '
spec:
  template:
    spec:
      serviceAccountName: invoice-reader
      automountServiceAccountToken: false
      containers:
      - name: worker
        volumeMounts:
        - name: worker-token
          mountPath: /var/run/worker-auth
          readOnly: true
        - name: worker-ca
          mountPath: /var/run/worker-ca
          readOnly: true
      volumes:
      - name: worker-token
        projected:
          sources:
          - serviceAccountToken:
              path: token
              audience: https://kubernetes.default.svc
              expirationSeconds: 3600
      - name: worker-ca
        configMap:
          name: kube-root-ca.crt
          items:
          - key: ca.crt
            path: ca.crt
'
kubectl -n "$NS" rollout status deploy/invoice-reader --timeout=180s
