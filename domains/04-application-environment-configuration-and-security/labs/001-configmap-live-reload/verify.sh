#!/usr/bin/env bash
set -euo pipefail
K=(kubectl --context kind-ckad-labs -n ckad-d4-001)
score=0; total=10
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS $name"; score=$((score+1)); else echo "FAIL $name"; fi; }
eq() { [[ "$1" == "$2" ]]; }
ctx() { [[ "$(kubectl config current-context)" == "kind-ckad-labs" ]]; }
ns() { kubectl --context kind-ckad-labs get ns ckad-d4-001 -o jsonpath='{.metadata.labels.app\.kubernetes\.io/part-of}' | grep -qx ckad-labs; }
cm() { eq "$("${K[@]}" get cm pricing-settings -o jsonpath='{.data.discount\.txt}')" 15; }
available() { "${K[@]}" rollout status deploy/pricing-api --timeout=60s; }
volume() { eq "$("${K[@]}" get deploy pricing-api -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}')" pricing-settings; }
readonly() { eq "$("${K[@]}" get deploy pricing-api -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}')" true; }
no_subpath() { eq "$("${K[@]}" get deploy pricing-api -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].subPath}')" ""; }
pod() { "${K[@]}" get pod -l app=pricing-api -o jsonpath='{.items[0].metadata.name}'; }
file() { local p; p="$(pod)"; eq "$("${K[@]}" exec "$p" -- cat /etc/pricing/discount.txt)" 15; }
uid() { local baseline current; baseline="$("${K[@]}" get ns ckad-d4-001 -o jsonpath='{.metadata.annotations.ckad-labs\.io/baseline-uid}')"; current="$("${K[@]}" get pod -l app=pricing-api -o jsonpath='{.items[0].metadata.uid}')"; [[ -n "$baseline" && "$baseline" == "$current" ]]; }
http() { local name="ckad-d4-001-check-$$"; "${K[@]}" run "$name" --restart=Never --rm -i --image=busybox:1.36 --command -- sh -c 'wget -q -T 10 -O - http://pricing-api.ckad-d4-001.svc.cluster.local/ | grep -qx "discount=15"'; }
check context ctx
check namespace ns
check configmap cm
check deployment available
check volume_reference volume
check readonly_mount readonly
check no_subpath no_subpath
check file_content file
check pod_uid_unchanged uid
check service_http http
echo "SCORE $score/$total"
[[ "$score" -eq "$total" ]]
