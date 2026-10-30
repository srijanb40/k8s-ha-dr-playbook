# Kubernetes HA & Disaster Recovery Playbook

Enterprise-style Kubernetes High Availability (HA), Disaster Recovery (DR), operational runbooks and recovery automation.

## Overview

This project demonstrates practical Kubernetes platform engineering and Site Reliability Engineering capabilities through:

- Multi-control-plane Kubernetes architecture
- Independent primary and DR Kubernetes clusters
- Control-plane and worker-node recovery procedures
- etcd backup and restore procedures
- Application availability and disruption management
- DR readiness checks and recovery validation
- Prometheus alerting examples
- Operational runbooks and DR test reporting
- RTO/RPO objectives and recovery evidence

## Architecture

The reference architecture consists of:

1. Primary Kubernetes cluster
2. Independent DR Kubernetes cluster
3. HAProxy / Keepalived API endpoint design
4. Cilium networking (optional lab implementation)
5. Application traffic management using DNS/GSLB or load balancers
6. Separate application data replication and recovery processes

The two Kubernetes clusters maintain independent control planes and etcd databases.

## Technology Stack

| Area                    | Technology                          |
| ----------------------- | ----------------------------------- |
| Container orchestration | Kubernetes                          |
| Cluster deployment      | kubeadm                             |
| Container runtime       | CRI-O / containerd                  |
| Networking              | Cilium                              |
| Load balancing          | HAProxy / Keepalived                |
| Monitoring              | Prometheus / Grafana                |
| Logging                 | Elasticsearch / Kibana              |
| Deployment              | Helm / Argo CD                      |
| Automation              | Bash / GitHub Actions               |
| Security                | RBAC / Pod Security / NetworkPolicy |

## Quick Start

```bash
kubectl config get-contexts

kubectl --context primary apply -f kubernetes/
kubectl --context dr apply -f kubernetes/

kubectl --context primary get pods -n dr-demo
kubectl --context dr get pods -n dr-demo
```

## Important Safety Considerations

- Never run two writable copies of a stateful application against the same logical dataset without a supported consistency design.
- Fence the primary site before activating DR writes.
- Encrypt etcd backups and store them off-site.
- Test restore procedures in an isolated environment.
- Validate application data, storage, DNS and dependencies before declaring DR successful.
- Do not use the example recovery targets as production commitments.

## Project Status

Reference implementation and lab playbook.
Individual recovery scenarios must be tested and evidence recorded
before claiming operational readiness.

## Author

Srijan Barua
DevOps & Platform Engineering Lead
