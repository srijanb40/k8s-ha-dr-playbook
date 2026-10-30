# Proposed architecture

![1793384491722](image/architecture/1793384491722.png)


## Primary data center — DC1

**HAProxy / Keepalived** - API VIP and traffic entry

**3 control planes** - kubeadm / etcd HA

**Worker nodes** - Application workloads

Replication · Health checks · Traffic failover

## Disaster recovery data center — DC2

**DR load balancer** - API / application entry

**DR Kubernetes** - Independent cluster 

**DR workloads** - Replicated application state

# **Event-Driven Architecture and Distributed Resilience**

![1793384931804](image/architecture/1793384931804.png)

# **Self Healing in Action**

![1793384984443](image/architecture/1793384984443.png)
