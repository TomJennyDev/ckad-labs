#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d4-005
echo "Negative A: extra pod rejected by quota"
if kubectl -n "$NS" run extra --image=nginx:1.27-alpine --restart=Never --requests='cpu=200m,memory=64Mi' --limits='cpu=250m,memory=128Mi'; then
 kubectl -n "$NS" delete pod extra --ignore-not-found
 echo "FAIL: unexpected admission"; exit 1
fi
echo "Negative B: max per-container CPU enforced by LimitRange"
if kubectl -n "$NS" run too-large --image=nginx:1.27-alpine --restart=Never --requests='cpu=1200m,memory=64Mi' --limits='cpu=1200m,memory=128Mi'; then
 kubectl -n "$NS" delete pod too-large --ignore-not-found
 echo "FAIL: unexpected admission"; exit 1
fi
echo "PASS: both invalid pods rejected"
