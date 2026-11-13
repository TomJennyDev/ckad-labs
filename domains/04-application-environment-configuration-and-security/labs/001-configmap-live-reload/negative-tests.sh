#!/usr/bin/env bash
set -euo pipefail
K=(kubectl --context kind-ckad-labs)
N=ckad-d4-001-negative
trap '"${K[@]}" delete ns "$N" --ignore-not-found --wait=false >/dev/null 2>&1 || true' EXIT
"${K[@]}" create ns "$N" --dry-run=client -o yaml | "${K[@]}" apply -f -
"${K[@]}" -n "$N" create configmap demo --from-literal=value=before
cat <<'YAML' | "${K[@]}" -n "$N" apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: projection
spec:
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh","-c","sleep 3600"]
      volumeMounts:
        - {name: config, mountPath: /normal, readOnly: true}
        - {name: config, mountPath: /subpath/value, subPath: value, readOnly: true}
  volumes:
    - name: config
      configMap:
        name: demo
YAML
"${K[@]}" -n "$N" wait pod/projection --for=condition=Ready --timeout=120s
"${K[@]}" -n "$N" patch cm demo --type merge -p '{"data":{"value":"after"}}'
ok=false
for i in $(seq 1 60); do
  normal="$("${K[@]}" -n "$N" exec projection -- cat /normal/value 2>/dev/null || true)"
  sub="$("${K[@]}" -n "$N" exec projection -- cat /subpath/value 2>/dev/null || true)"
  if [[ "$normal" == after && "$sub" == before ]]; then ok=true; break; fi
  sleep 2
done
[[ "$ok" == true ]] || { echo "FAIL: volume propagation/subPath behavior not observed"; exit 1; }
echo "PASS: regular volume updated, subPath remained stale"
