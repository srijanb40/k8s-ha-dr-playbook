# Runbook: Primary DC to DR DC Failover

## 1. Purpose

Restore application availability from the DR Kubernetes cluster when the primary data center is unavailable or declared unsafe.

## 2. Preconditions

- Incident commander has approved DR activation.
- Primary-site status and failure scope are understood.
- Primary application writes have been fenced or isolated.
- DR cluster API and worker nodes are healthy.
- Application data replication status has been reviewed.
- DR application replicas are running and ready.
- DNS/GSLB or external traffic-management access is available.
- Stakeholders have been informed.

## 3. Execution

### Step 1: Validate DR cluster

```bash
kubectl --context dr get nodes
kubectl --context dr get pods -A
kubectl --context dr get deployments -n dr-demo
```

### Step 2: Validate application

```bash
./scripts/failover-readiness.sh
```

Run the script with the DR context selected or update the script to accept a context explicitly before operational use.

### Step 3: Validate application dependencies

- Database availability and replication lag
- Storage and persistent volume availability
- Secrets and certificates
- External APIs and DNS dependencies
- Ingress and load-balancer health

### Step 4: Approve traffic switching

Use the approved DNS/GSLB or load-balancer procedure. Do not rely on Kubernetes Service changes to switch traffic between independent clusters.

### Step 5: Verify service

- Confirm external HTTP response.
- Confirm application transaction success.
- Confirm error rate and latency.
- Confirm database consistency.
- Confirm monitoring and alerting.

## 4. Recovery evidence

Record:

- Incident declaration time
- DR activation approval time
- Primary isolation/fencing time
- DR application ready time
- Traffic switch completion time
- First successful external transaction
- Data loss / replication lag
- Validation results and approver

## 5. Exit criteria

The incident commander confirms service restoration, business validation and stakeholder communication.

```bash

**Critical safety rule:** Never activate writable workloads in DR while the primary may still be accepting writes. Prevent split-brain through fencing, isolation, or a verified failover control. Traffic switching alone is not fencing.

## 9. Monitoring and alerting

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: k8s-ha-dr-alerts
  namespace: monitoring
  labels:
    release: prometheus
spec:
  groups:
    - name: k8s-ha-dr.rules
      rules:
        - alert: KubernetesNodeNotReady
          expr: |
            kube_node_status_condition{
              condition="Ready",
              status="true"
            } == 0
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: Kubernetes node is not ready
            description: A Kubernetes node has been NotReady for more than 5 minutes.

        - alert: KubernetesDeploymentUnavailable
          expr: |
            kube_deployment_status_replicas_available
            <
            kube_deployment_spec_replicas
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: Deployment replicas are below desired count
            description: A deployment has fewer available replicas than expected.

        - alert: KubernetesPersistentVolumeClaimPending
          expr: |
            kube_persistentvolumeclaim_status_phase{
              phase="Pending"
            } == 1
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: PersistentVolumeClaim is pending
            description: A PVC has remained pending for more than 10 minutes.
```

## 6. RTO and RPO objectives

Define targets as design objectives, then demonstrate measured results in your lab. Do not present targets as achieved results until you have run and recorded the exercises.

| Recovery scenario                    | Illustrative RTO target | Illustrative RPO target             |
| ------------------------------------ | ----------------------- | ----------------------------------- |
| Single worker failure                | 5 minutes               | 0 for stateless workloads           |
| Single control-plane failure         | 10 minutes              | 0 if etcd quorum remains healthy    |
| Primary application instance failure | 2 minutes               | Dependsondatastore                  |
| Full primary DC outage               | 30 minutes              | 5minutes                            |
| etcd disaster recovery               | 60 minutes              | Last verified snapshot/backup point |

Definitions
- RTO: Maximum acceptable time to restore service.
- RPO: Maximum acceptable data loss measured in time.
- Measured RTO: First successful business-level transaction after incident declaration.
- Measured RPO: Difference between the latest recoverable business data point and the outage point.

## 13. Deployment and lab execution
You can test this project using two independent Kubernetes clusters. For a smaller lab, use two kubeadm clusters, or use two local clusters created with Kind.

### Step 1 — Configure cluster contexts

```bash
$ kubectl config get-contexts
$ kubectl config rename-context \
  <primary-context-name> primary
$ kubectl config rename-context \
  <dr-context-name> dr
```

Step 2 — Deploy the sample application to both clusters

```bash
# Primary cluster

kubectl --context primary apply -f kubernetes/
```
```bash
## DR cluster

kubectl --context dr apply -f kubernetes/
```
### Step 3 — Validate deployment

```bash
kubectl --context primary get pods -n dr-demo
kubectl --context primary get svc -n dr-demo

kubectl --context dr get pods -n dr-demo
kubectl --context dr get svc -n dr-demo
```

### Step 4 — Validate DR readiness

```bash
$ kubectl config use-context dr
$ chmod +x scripts/*.sh

./scripts/cluster-health-check.sh dr
./scripts/failover-readiness.sh
```

### Step 5 — Simulate a worker failure

In a controlled lab only:

```bash
kubectl --context primary cordon <worker-node>

kubectl --context primary drain <worker-node> \
  --ignore-daemonsets \
  --delete-emptydir-data
```

Observe pod rescheduling and service availability. Restore the node when appropriate:
```bash
kubectl --context primary uncordon <worker-node>
```

Do not run drain on production nodes without checking PDBs, workload capacity, storage behavior, and change approval.

### Step 6 — Simulate a DR traffic switch

For the first iteration, use a controlled external load balancer or a test DNS record. Switch the test endpoint from the primary ingress to the DR ingress only after confirming DR readiness and primary write fencing. Record the timestamps in the test report.