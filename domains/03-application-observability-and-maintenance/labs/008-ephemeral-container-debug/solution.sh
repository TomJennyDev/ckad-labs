#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-008
[ "$(kubectl config current-context)" = "kind-ckad-labs" ] || { echo "Expected kind-ckad-labs context"; exit 2; }
kubectl -n "$NS" rollout status deployment/ledger-api --timeout=120s
pod=$(kubectl -n "$NS" get pods -l app=ledger-api -o jsonpath='{.items[0].metadata.name}')
if kubectl -n "$NS" get pod "$pod" -o jsonpath='{.spec.ephemeralContainers[*].name}' | grep -qw debugger; then
  echo "debugger already attached; ephemeral containers cannot be removed or restarted. Recreate lab to retry."
else
  kubectl -n "$NS" debug -it=false "pod/$pod" --container=debugger --image=busybox:1.36 -- sh -c 'nslookup ledger-api.ckad-d3-008.svc.cluster.local && wget -q -T 10 -O /dev/null http://ledger-api.ckad-d3-008.svc.cluster.local/ && echo HTTP_OK'
fi
for i in $(seq 1 30); do
  code=$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.status.ephemeralContainerStatuses[?(@.name=="debugger")].state.terminated.exitCode}' 2>/dev/null || true)
  [ "$code" = 0 ] && break
  sleep 2
done
bash "$(dirname "$0")/verify.sh"
