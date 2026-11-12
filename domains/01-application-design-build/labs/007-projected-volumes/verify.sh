#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/assert.sh"
NS="${NS:-ckad-d1-007}"
pod=projected-app
get() { k -n "$NS" get pod "$pod" -o "jsonpath=$1" 2>/dev/null || true; }
eq "$(get '{.spec.serviceAccountName}')" workload-reader "ServiceAccount identity"
eq "$(get '{.spec.automountServiceAccountToken}')" false "Default token automount disabled"
eq "$(get '{.spec.volumes[0].projected.sources[0].configMap.name}')" runtime-settings "ConfigMap projection"
eq "$(get '{.spec.volumes[0].projected.sources[1].secret.name}')" runtime-credentials "Secret projection"
eq "$(get '{.spec.volumes[0].projected.sources[2].downwardAPI.items[0].fieldRef.fieldPath}')" metadata.name "Downward API pod name"
eq "$(get '{.spec.volumes[0].projected.sources[3].serviceAccountToken.audience}')" ckad-training "Bound token audience"
eq "$(get '{.spec.volumes[0].projected.sources[3].serviceAccountToken.expirationSeconds}')" 3600 "Bound token TTL"
eq "$(get '{.spec.containers[0].volumeMounts[0].readOnly}')" true "Read-only volume mount"
ok "Pod Ready" k -n "$NS" wait --for=condition=Ready pod/"$pod" --timeout=120s
eq "$(k -n "$NS" exec "$pod" -- cat /var/run/app/mode 2>/dev/null || true)" production "ConfigMap mounted content"
eq "$(k -n "$NS" exec "$pod" -- cat /var/run/app/feature-flag 2>/dev/null || true)" enabled "Feature flag mounted"
eq "$(k -n "$NS" exec "$pod" -- cat /var/run/app/credentials/api-key 2>/dev/null || true)" lab-only-key "Secret mounted content"
eq "$(k -n "$NS" exec "$pod" -- cat /var/run/app/metadata/pod-name 2>/dev/null || true)" projected-app "Downward API pod name"
eq "$(k -n "$NS" exec "$pod" -- cat /var/run/app/metadata/namespace 2>/dev/null || true)" "$NS" "Downward API namespace"
ok "Projected bound token is present, non-empty (never print it)" k -n "$NS" exec "$pod" -- test -s /var/run/app/identity/token
finish
