#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
./solution.sh
restore() { kubectl apply -f solution.yaml >/dev/null; }
trap restore EXIT
for entry in 'concurrencyPolicy Allow' 'suspend true' 'backoffLimit 6' 'restartPolicy OnFailure' 'image busybox:1.35'; do
  read -r field value <<< "$entry"
  case "$field" in
    concurrencyPolicy|suspend)
      kubectl -n ckad-d2-012 patch cronjob billing-reconcile --type=merge -p "{\"spec\":{\"$field\":$([ "$field" = suspend ] && echo "$value" || echo "\"$value\"")}}" >/dev/null ;;
    backoffLimit)
      kubectl -n ckad-d2-012 patch cronjob billing-reconcile --type=merge -p '{"spec":{"jobTemplate":{"spec":{"backoffLimit":6}}}}' >/dev/null ;;
    restartPolicy)
      kubectl -n ckad-d2-012 patch cronjob billing-reconcile --type=merge -p '{"spec":{"jobTemplate":{"spec":{"template":{"spec":{"restartPolicy":"OnFailure"}}}}}}' >/dev/null ;;
    image)
      kubectl -n ckad-d2-012 set image cronjob/billing-reconcile reconcile="$value" >/dev/null ;;
  esac
  if ./verify.sh >/dev/null 2>&1; then echo "FAIL grader accepted $field=$value"; exit 1; fi
  echo "PASS negative $field=$value"
  restore
done
./verify.sh
