#!/usr/bin/env bash
set -euo pipefail
n=ckad-d5-007
trap 'bash "$(dirname "$0")/solution.sh" >/dev/null' EXIT
kubectl -n "$n" patch networkpolicy orders-ingress --type=merge -p '{"spec":{"ingress":[{"from":[{"podSelector":{"matchLabels":{"role":"intruder"}}}],"ports":[{"protocol":"TCP","port":5678}]}]}}'
if bash "$(dirname "$0")/verify.sh"; then echo "FAIL: negative mutation accepted"; exit 1; fi
echo "PASS: negative policy rejected"
