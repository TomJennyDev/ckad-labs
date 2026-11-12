#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"
NS="${NS:-ckad-d1-010}"
ensure_cluster
ensure_owner "$NS"
get() { k -n "$NS" get daemonset node-observer -o "jsonpath=$1" 2>/dev/null || true; }
eq "$(get '{.spec.selector.matchLabels.app}')" "node-observer" "DaemonSet selector"
eq "$(get '{.spec.template.metadata.labels.role}')" "telemetry" "Pod telemetry label"
eq "$(get '{.spec.template.spec.containers[0].image}')" "busybox:1.36" "Valid agent image"
eq "$(get '{.spec.updateStrategy.type}')" "RollingUpdate" "RollingUpdate strategy"
eq "$(get '{.spec.updateStrategy.rollingUpdate.maxUnavailable}')" "1" "One unavailable at a time"
eq "$(get '{.spec.template.spec.containers[0].env[0].valueFrom.fieldRef.fieldPath}')" "spec.nodeName" "Downward API node name"
eq "$(get '{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator}')" "DoesNotExist" "Control-plane exclusion operator"
eq "$(get '{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}')" "node-role.kubernetes.io/control-plane" "Control-plane exclusion key"
ok "DaemonSet rollout" k -n "$NS" rollout status daemonset/node-observer --timeout=180s
desired="$(get '{.status.desiredNumberScheduled}')"
ready="$(get '{.status.numberReady}')"
eq "$ready" "$desired" "All eligible nodes Ready"
if [[ "$desired" =~ ^[0-9]+$ ]] && (( desired >= 1 )); then
  echo "PASS eligible node count $desired"
else
  echo "FAIL no eligible worker nodes"; fails=$((fails+1))
fi
nodes="$(k -n "$NS" get pods -l app=node-observer -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' 2>/dev/null || true)"
unique="$(printf '%s\n' "$nodes" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')"
eq "$unique" "$desired" "One agent per eligible worker node"
while IFS= read -r pod; do
  [[ -n "$pod" ]] || continue
  ok "Agent $pod reports node name" bash -c 'kubectl --context kind-ckad-labs -n "$1" logs "$2" -c observer --tail=30 | grep -Eq "^node-observer node=[^ ]+ pod=[^ ]+$"' _ "$NS" "$pod"
done < <(k -n "$NS" get pods -l app=node-observer -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
finish
