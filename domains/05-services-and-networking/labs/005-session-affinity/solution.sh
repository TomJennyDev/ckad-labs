#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d5-005
kubectl -n "$NS" patch svc orders --type=merge -p '{"spec":{"sessionAffinity":"ClientIP","sessionAffinityConfig":{"clientIP":{"timeoutSeconds":10800}}}}'
kubectl -n "$NS" get svc orders -o jsonpath='{.spec.sessionAffinity}{"\n"}'
