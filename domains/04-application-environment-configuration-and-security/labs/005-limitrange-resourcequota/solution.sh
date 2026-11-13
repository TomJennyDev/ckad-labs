#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-005
kubectl -n "$NS" set resources deployment/report-api --containers=web --requests=cpu=100m,memory=64Mi --limits=cpu=250m,memory=128Mi
kubectl -n "$NS" rollout status deployment/report-api --timeout=180s
