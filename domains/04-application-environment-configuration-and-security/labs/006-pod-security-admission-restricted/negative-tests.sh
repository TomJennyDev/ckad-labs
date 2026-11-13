#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-006
kubectl get ns "$NS" >/dev/null
bad=$(mktemp); trap 'rm -f "$bad"' EXIT
cat >"$bad" <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: forbidden-root
  namespace: ckad-d4-006
spec:
  containers:
    - name: test
      image: busybox:1.36
      command: ["sleep", "3600"]
      securityContext:
        privileged: true
YAML
if kubectl create -f "$bad" > /dev/null 2>&1; then
  kubectl -n "$NS" delete pod forbidden-root --ignore-not-found
  echo "FAIL: admission accepted privileged Pod"; exit 1
fi
echo "PASS: restricted admission rejects privileged Pod"
kubectl -n "$NS" get pods -l app=payments-api
