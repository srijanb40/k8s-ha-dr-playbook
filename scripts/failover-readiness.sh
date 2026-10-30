#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE="${NAMESPACE:-dr-demo}"
DEPLOYMENT="${DEPLOYMENT:-dr-demo-app}"
SERVICE="${SERVICE:-dr-demo-service}"

echo "Checking DR cluster readiness..."

kubectl get nodes
kubectl rollout status \
  "deployment/${DEPLOYMENT}" \
  -n "$NAMESPACE" \
  --timeout=120s

DESIRED="$(kubectl get deployment "$DEPLOYMENT" \
  -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')"

READY="$(kubectl get deployment "$DEPLOYMENT" \
  -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')"

DESIRED="${DESIRED:-0}"
READY="${READY:-0}"

if (( READY < DESIRED || DESIRED == 0 )); then
  echo "FAIL: Deployment is not fully ready."
  exit 1
fi

kubectl get service "$SERVICE" -n "$NAMESPACE"
kubectl get endpointslice -n "$NAMESPACE" \
  -l "kubernetes.io/service-name=${SERVICE}"

echo "PASS: Application replicas are ready."
echo "NEXT: Validate ingress, DNS, data consistency, dependencies and external reachability."