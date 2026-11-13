#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-006
pass=0
check() { if eval "$2"; then echo "PASS $1"; pass=$((pass+1)); else echo "FAIL $1"; exit 1; fi; }
check namespace 'kubectl get ns "$NS" >/dev/null'
check enforce_restricted '[ "$(kubectl get ns "$NS" -o jsonpath="{.metadata.labels.pod-security\\.kubernetes\\.io/enforce}")" = restricted ]'
check replicas '[ "$(kubectl -n "$NS" get deploy payments-api -o jsonpath="{.status.readyReplicas}")" = 2 ]'
check nonroot '[ "$(kubectl -n "$NS" get deploy payments-api -o jsonpath="{.spec.template.spec.securityContext.runAsNonRoot}")" = true ]'
check uid '[ "$(kubectl -n "$NS" get deploy payments-api -o jsonpath="{.spec.template.spec.securityContext.runAsUser}")" = 10001 ]'
check seccomp '[ "$(kubectl -n "$NS" get deploy payments-api -o jsonpath="{.spec.template.spec.securityContext.seccompProfile.type}")" = RuntimeDefault ]'
check no_escalation '[ "$(kubectl -n "$NS" get deploy payments-api -o jsonpath="{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}")" = false ]'
check no_privileged '[ "$(kubectl -n "$NS" get deploy payments-api -o jsonpath="{.spec.template.spec.containers[0].securityContext.privileged}")" = false ]'
check drop_all 'kubectl -n "$NS" get deploy payments-api -o jsonpath="{.spec.template.spec.containers[0].securityContext.capabilities.drop[*]}" | grep -qw ALL'
check pods 'test "$(kubectl -n "$NS" get pods -l app=payments-api --field-selector=status.phase=Running -o name | wc -l | tr -d " ")" = 2'
check service 'kubectl -n "$NS" get svc payments-api >/dev/null'
echo "SCORE: $pass/11"
