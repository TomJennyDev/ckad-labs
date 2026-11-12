#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"

NS="${NS:-ckad-d1-005}"
ok "PVC Bound" k -n "$NS" wait --for=jsonpath='{.status.phase}'=Bound pvc/journal --timeout=120s
eq "$(k -n "$NS" get pvc journal -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null || true)" "ReadWriteOnce" "PVC access mode"
eq "$(k -n "$NS" get pod archiver -o jsonpath='{.spec.volumes[0].name}' 2>/dev/null || true)" "cache" "Ephemeral volume name"
eq "$(k -n "$NS" get pod archiver -o jsonpath='{.spec.volumes[1].persistentVolumeClaim.claimName}' 2>/dev/null || true)" "journal" "PVC reference"
ok "Pod Ready" k -n "$NS" wait --for=condition=Ready pod/archiver --timeout=120s
eq "$(k -n "$NS" exec pod/archiver -- cat /data/state.txt 2>/dev/null || true)" "durable-v1" "Persistent file"
eq "$(k -n "$NS" exec pod/archiver -- cat /cache/cache.txt 2>/dev/null || true)" "temporary-v1" "Ephemeral file"
finish
