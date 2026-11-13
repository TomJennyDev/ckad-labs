#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-003
AS="system:serviceaccount:$NS:auditor"
pass=0
fail=0
check() {
  local title="$1"; shift
  if "$@" >/dev/null 2>&1; then printf 'PASS %s\n' "$title"; pass=$((pass+1)); else printf 'FAIL %s\n' "$title"; fail=$((fail+1)); fi
}
allowed() { [[ "$(kubectl auth can-i "$1" "$2" -n "$NS" --as="$AS" 2>/dev/null)" == yes ]]; }
denied() { [[ "$(kubectl auth can-i "$1" "$2" -n "$NS" --as="$AS" 2>/dev/null)" == no ]]; }
role_exact() {
  [[ "$(kubectl -n "$NS" get role auditor-reader -o jsonpath='{.rules[0].resources[0]}')" == configmaps ]] &&
  [[ "$(kubectl -n "$NS" get role auditor-reader -o jsonpath='{.rules[0].resourceNames[0]}')" == public-settings ]] &&
  [[ "$(kubectl -n "$NS" get role auditor-reader -o jsonpath='{.rules[0].verbs[0]}')" == get ]] &&
  [[ "$(kubectl -n "$NS" get role auditor-reader -o jsonpath='{.rules[*].verbs[*]}' | wc -w | tr -d ' ')" == 1 ]]
}
binding_exact() {
  [[ "$(kubectl -n "$NS" get rolebinding auditor-binding -o jsonpath='{.roleRef.name}')" == auditor-reader ]] &&
  [[ "$(kubectl -n "$NS" get rolebinding auditor-binding -o jsonpath='{.subjects[0].name}')" == auditor ]]
}
pod_identity() {
  [[ "$(kubectl -n "$NS" get pod audit-client -o jsonpath='{.spec.serviceAccountName}')" == auditor ]] &&
  [[ "$(kubectl -n "$NS" get pod audit-client -o jsonpath='{.status.phase}')" == Running ]]
}
api_get() {
  kubectl -n "$NS" exec audit-client -- sh -c '
    TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    curl -fsS --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
      -H "Authorization: Bearer $TOKEN" \
      "https://kubernetes.default.svc/api/v1/namespaces/ckad-d4-003/configmaps/public-settings" | grep -q ap-southeast-1
  '
}
api_secret_denied() {
  kubectl -n "$NS" exec audit-client -- sh -c '
    TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    CODE=$(curl -sS -o /dev/null -w "%{http_code}" \
      --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
      -H "Authorization: Bearer $TOKEN" \
      "https://kubernetes.default.svc/api/v1/namespaces/ckad-d4-003/secrets/payroll-credential")
    test "$CODE" = 403
  '
}
check "Namespace exists" kubectl get ns "$NS"
check "Role exact least privilege" role_exact
check "RoleBinding correct" binding_exact
check "Pod running with auditor SA" pod_identity
check "Allowed named ConfigMap" allowed get configmap/public-settings
check "Denied other ConfigMap" denied get configmap/other-settings
check "Denied list ConfigMaps" denied list configmaps
check "Denied Secret read" denied get secret/payroll-credential
check "Denied create Pods" denied create pods
check "In-pod token reaches ConfigMap API" api_get
check "In-pod token gets HTTP 403 on Secret" api_secret_denied
printf 'RESULT %d passed / %d failed\n' "$pass" "$fail"
test "$fail" -eq 0
