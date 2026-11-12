#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$D/../../../.." && pwd)"
source "$ROOT/lib/common.sh"
NS="${NS:-ckad-d1-012}"
ensure_cluster
ensure_owner "$NS"
score=0
max=100
pass() { echo "PASS ($2 pts): $1"; score=$((score+$2)); }
miss() { echo "FAIL (0/$2 pts): $1"; }
field() { k -n "$NS" get "$1" -o "jsonpath=$2" 2>/dev/null || true; }
# 1: workload scaling and rollout (20)
if [[ "$(field deploy/gateway '{.spec.replicas}')" == 2 ]] && [[ "$(field deploy/gateway '{.status.readyReplicas}')" == 2 ]]; then pass "Q1: two ready replicas" 20; else miss "Q1: two ready replicas" 20; fi
# 2: init container and shared volume (25)
init="$(field deploy/gateway '{.spec.template.spec.initContainers[0].name}')"
initmount="$(field deploy/gateway '{.spec.template.spec.initContainers[0].volumeMounts[0].name}')"
webmount="$(field deploy/gateway '{.spec.template.spec.containers[0].volumeMounts[0].name}')"
vol="$(field deploy/gateway '{.spec.template.spec.volumes[0].name}')"
if [[ "$init" == prepare && "$initmount" == work && "$webmount" == work && "$vol" == work ]] && [[ "$(field deploy/gateway '{.spec.template.spec.volumes[0].emptyDir}')" == "{}" ]]; then
  pod="$(k -n "$NS" get pods -l app=gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [[ -n "$pod" ]] && [[ "$(k -n "$NS" exec "$pod" -c web -- cat /work/status.txt 2>/dev/null || true)" == prepared ]]; then pass "Q2: init container writes shared file" 25; else miss "Q2: shared file not readable" 25; fi
else miss "Q2: init container + emptyDir" 25; fi
# 3: requests and limits (15)
if [[ "$(field deploy/gateway '{.spec.template.spec.containers[0].resources.requests.cpu}')" == 25m && "$(field deploy/gateway '{.spec.template.spec.containers[0].resources.requests.memory}')" == 32Mi && "$(field deploy/gateway '{.spec.template.spec.containers[0].resources.limits.cpu}')" == 150m && "$(field deploy/gateway '{.spec.template.spec.containers[0].resources.limits.memory}')" == 128Mi ]]; then pass "Q3: resources" 15; else miss "Q3: resources" 15; fi
# 4: Job completion (25)
if [[ "$(field job/batch-report '{.spec.completions}')" == 2 && "$(field job/batch-report '{.spec.parallelism}')" == 1 && "$(field job/batch-report '{.spec.backoffLimit}')" == 2 && "$(field job/batch-report '{.status.succeeded}')" == 2 ]]; then pass "Q4: Job complete" 25; else miss "Q4: Job complete" 25; fi
# 5: CronJob (15)
if [[ "$(field cronjob/scheduled-report '{.spec.schedule}')" == "*/10 * * * *" && "$(field cronjob/scheduled-report '{.spec.concurrencyPolicy}')" == Forbid && "$(field cronjob/scheduled-report '{.spec.suspend}')" == true ]]; then pass "Q5: CronJob safety" 15; else miss "Q5: CronJob safety" 15; fi
echo "SCORE: $score/$max"
if (( score >= 66 )); then echo "PASS (practice threshold 66%; not an official CKAD grade)"; else echo "FAIL (practice threshold 66%)"; exit 1; fi
