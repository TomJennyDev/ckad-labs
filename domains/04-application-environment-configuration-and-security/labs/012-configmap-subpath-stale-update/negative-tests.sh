#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-012
DIR=$(cd "$(dirname "$0")" && pwd)
kubectl -n "$NS" patch deployment pricing-api --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/0/mountPath","value":"/etc/pricing/price.txt"},{"op":"add","path":"/spec/template/spec/containers/0/volumeMounts/0/subPath","value":"price.txt"}]'
kubectl -n "$NS" patch cm pricing-config --type=merge -p '{"data":{"price.txt":"100"}}'
kubectl -n "$NS" rollout restart deploy/pricing-api
kubectl -n "$NS" rollout status deploy/pricing-api --timeout=120s
pod=$(kubectl -n "$NS" get pod -l app=pricing-api -o jsonpath='{.items[0].metadata.name}')
[ "$(kubectl -n "$NS" exec "$pod" -- cat /etc/pricing/price.txt)" = 100 ] || { echo "FAIL: baseline is not 100"; exit 1; }
kubectl -n "$NS" patch cm pricing-config --type=merge -p '{"data":{"price.txt":"200"}}'
sleep 12
[ "$(kubectl -n "$NS" exec "$pod" -- cat /etc/pricing/price.txt)" = 100 ] || { echo "FAIL: subPath unexpectedly refreshed"; exit 1; }
if bash "$DIR/verify.sh"; then echo "FAIL: verifier accepted stale subPath"; exit 1; fi
echo "PASS negative: stale subPath rejected. Restore with bash solution.sh"
