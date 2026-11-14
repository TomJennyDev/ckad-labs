#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-010
kubectl -n "$NS" get cm catalog-config-v1 >/dev/null
echo "[1] immutable ConfigMap mutation must fail"
if kubectl -n "$NS" patch cm catalog-config-v1 --type=merge -p '{"data":{"CATALOG_VERSION":"invalid"}}' >/dev/null 2>&1; then
  echo "FAIL: immutable v1 accepted mutation" >&2; exit 1
fi
echo "[2] missing key must prevent container start"
kubectl -n "$NS" delete pod missing-config-key --ignore-not-found --wait=true >/dev/null
trap 'kubectl -n "$NS" delete pod missing-config-key --ignore-not-found --wait=false >/dev/null 2>&1 || true' EXIT
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: missing-config-key
spec:
  restartPolicy: Never
  containers:
    - name: test
      image: busybox:1.36
      command: ["sh","-c","sleep 300"]
      env:
        - name: MISSING
          valueFrom:
            configMapKeyRef:
              name: catalog-config-v1
              key: NOT_PRESENT
YAML
for i in $(seq 1 30); do
  reason=$(kubectl -n "$NS" get pod missing-config-key -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || true)
  if [[ "$reason" == "CreateContainerConfigError" ]]; then
    echo "PASS: mutation rejected and missing key caused CreateContainerConfigError"; exit 0
  fi
  sleep 2
done
echo "FAIL: missing key did not surface CreateContainerConfigError" >&2
exit 1
