#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
: "${NS:=ckad-d1-006}"
D="$(cd "$(dirname "$0")" && pwd)"
k -n "$NS" apply -f "$D/solution.yaml"

