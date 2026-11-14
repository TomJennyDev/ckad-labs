#!/usr/bin/env bash
set -euo pipefail
kubectl -n ckad-d4-009 patch deployment checkout-api --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","envFrom":[{"configMapRef":{"name":"checkout-defaults"}},{"configMapRef":{"name":"checkout-overrides"}}],"env":[{"name":"API_KEY","valueFrom":{"secretKeyRef":{"name":"checkout-credentials","key":"API_KEY"}}},{"name":"APP_MODE","value":"production"}]}]}}}}'
kubectl -n ckad-d4-009 rollout status deployment/checkout-api --timeout=180s
