#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-012
kubectl -n "$NS" patch deployment pricing-api --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/0/mountPath","value":"/etc/pricing"},{"op":"remove","path":"/spec/template/spec/containers/0/volumeMounts/0/subPath"}]'
kubectl -n "$NS" rollout status deployment/pricing-api --timeout=120s
kubectl -n "$NS" patch configmap pricing-config --type=merge -p '{"data":{"price.txt":"200"}}'
echo "Wait for kubelet to refresh the ConfigMap projection; run bash verify.sh"
