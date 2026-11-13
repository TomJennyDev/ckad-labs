#!/usr/bin/env bash
set -euo pipefail
NS=ckad-d3-008
[ "$(kubectl config current-context)" = "kind-ckad-labs" ] || exit 2
pod=$(kubectl -n "$NS" get pods -l app=ledger-api -o jsonpath='{.items[0].metadata.name}')
# Negative tests are read-only; no mutation of the solved Pod.
if kubectl -n "$NS" exec "$pod" -c app -- sh -c 'command -v tcpdump' >/dev/null 2>&1; then echo "FAIL: minimal image unexpectedly has tcpdump"; exit 1; else echo "PASS: no tcpdump in app container"; fi
if kubectl -n "$NS" get pod "$pod" -o jsonpath='{.spec.containers[*].name}' | grep -qw debugger; then echo "FAIL: debugger incorrectly added as regular container"; exit 1; else echo "PASS: debugger not a regular container"; fi
if kubectl -n "$NS" get service missing-ledger >/dev/null 2>&1; then echo "FAIL: unexpected service"; exit 1; else echo "PASS: nonexistent Service absent"; fi
echo "Read-only negative checks passed. For a genuine failing grader case, run verify.sh before solution.sh in a fresh namespace."
