#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NS=ckad-d4-004
trap 'bash solution.sh >/dev/null' EXIT
bash solution.sh >/dev/null
kubectl -n "$NS" patch deployment gateway --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","securityContext":{"readOnlyRootFilesystem":false}}]}}}}'
if bash verify.sh >/dev/null 2>&1; then echo "FAIL: verifier accepted writable rootfs"; exit 1; fi
echo "PASS: writable rootfs rejected"
bash solution.sh >/dev/null
kubectl -n "$NS" patch deployment gateway --type=strategic -p '{"spec":{"template":{"spec":{"securityContext":{"runAsUser":10002}}}}}'
if bash verify.sh >/dev/null 2>&1; then echo "FAIL: verifier accepted wrong UID"; exit 1; fi
echo "PASS: wrong UID rejected"
bash solution.sh >/dev/null
kubectl -n "$NS" patch deployment gateway --type=json -p='[{"op":"remove","path":"/spec/template/spec/volumes/1"}]' 
if bash verify.sh >/dev/null 2>&1; then echo "FAIL: verifier accepted missing scratch volume"; exit 1; fi
echo "PASS: missing scratch rejected"
