#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
NS=ckad-d2-011
restore() { kubectl apply -f solution.yaml >/dev/null; kubectl -n "$NS" rollout status ds/node-agent --timeout=180s >/dev/null; }
trap restore EXIT
restore
check_reject() {
  if ./verify.sh >/dev/null 2>&1; then echo "FAIL: grader accepted $1" >&2; exit 1; fi
  echo "PASS negative: $1 rejected"
}
kubectl -n "$NS" patch ds node-agent --type=json -p='[{"op":"replace","path":"/spec/updateStrategy/rollingUpdate/maxUnavailable","value":2}]' >/dev/null
check_reject "wrong maxUnavailable"
restore
kubectl -n "$NS" patch ds node-agent --type=merge -p='{"spec":{"template":{"metadata":{"labels":{"release":"bad"}}}}}' >/dev/null
check_reject "wrong release label"
restore
kubectl -n "$NS" set image ds/node-agent agent=busybox:1.35 >/dev/null
check_reject "wrong image"
restore
kubectl -n "$NS" patch ds node-agent --type=json -p='[{"op":"remove","path":"/spec/template/spec/tolerations"}]' >/dev/null
check_reject "missing toleration"
restore
kubectl -n "$NS" patch ds node-agent --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/command","value":["/bin/sh","-c","echo wrong; sleep 3600"]}]' >/dev/null
check_reject "wrong runtime command"
restore
echo "PASS: 5 negative cases rejected; solution restored"
