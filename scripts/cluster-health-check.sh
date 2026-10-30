#!/usr/bin/env bash
set -Eeuo pipefail

CONTEXT="${1:-}"
OUTPUT="${2:-cluster-health-$(date +%Y%m%d-%H%M%S).txt}"

if [[ -n "$CONTEXT" ]]; then
  K=(kubectl --context "$CONTEXT")
else
  K=(kubectl)
fi

run_check() {
  local title="$1"
  shift

  echo
  echo "===== ${title} ====="
  "$@" || echo "WARNING: ${title} returned a non-zero status"
}

{
  echo "Kubernetes Cluster Health Report"
  echo "Timestamp: $(date -Is)"
  echo "Context: ${CONTEXT:-current-context}"

  run_check "Cluster information" "${K[@]}" cluster-info
  run_check "Node status" "${K[@]}" get nodes -o wide
  run_check "Unhealthy pods" "${K[@]}" get pods -A \
    --field-selector=status.phase!=Running,status.phase!=Succeeded

  run_check "System workloads" "${K[@]}" get pods -n kube-system
  run_check "Deployment status" "${K[@]}" get deployments -A
  run_check "Persistent volume status" "${K[@]}" get pv
  run_check "Storage claims" "${K[@]}" get pvc -A
  run_check "Pod disruption budgets" "${K[@]}" get pdb -A
  run_check "Recent warning events" "${K[@]}" get events -A \
    --field-selector type=Warning \
    --sort-by=.lastTimestamp

} 2>&1 | tee "$OUTPUT"

echo
echo "Report saved to: $OUTPUT"