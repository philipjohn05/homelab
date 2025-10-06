# My HomeLab

# Production-Grade Talos Kubernetes Cluster

A fully functional, high-availability Kubernetes cluster running on Talos Linux in a Proxmox homelab environment.

## Architecture Overview

```
                    ┌─────────────────────────┐
                    │   VIP: 10.x.x.100:6443  │
                    │    (kube-vip managed)   │
                    └────────────┬────────────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
        ┌────────▼────────┐ ┌───▼──────────┐ ┌─▼─────────────┐
        │  Control Plane  │ │ Control Plane│ │ Control Plane │
        │   10.x.x.101    │ │  10.x.x.102  │ │  10.x.x.103   │
        └─────────────────┘ └──────────────┘ └───────────────┘
                 │               │               │
        ┌────────┴───────────────┴───────────────┴──────┐
        │                                               │
   ┌────▼────────┐    ┌─────────────┐    ┌──────────────┐
   │   Worker    │    │   Worker    │    │   Worker     │
   │ 10.x.x.111  │    │ 10.x.x.112  │    │ 10.x.x.113   │
   └─────────────┘    └─────────────┘    └──────────────┘
```

## Cluster Specifications

| Component | Details |
|-----------|---------|
| **Nodes** | 3 Control Plane + 3 Worker |
| **OS** | Talos Linux 1.11.1 |
| **Kubernetes** | v1.34.0 |
| **Hypervisor** | Proxmox VE 8.x |
| **CNI** | Flannel |
| **HA Solution** | kube-vip |
| **Storage** | Local (NVMe) |

## Technology Stack

- **Talos Linux**: Immutable, API-driven Kubernetes OS
- **Proxmox VE**: Type-1 hypervisor for VM management
- **kube-vip**: Control plane high availability via VIP
- **Flannel**: Pod networking (CNI)
- **etcd**: Distributed key-value store (3-node cluster)

## Prerequisites

- Proxmox VE 8.x installed and configured
- Network with available IP addresses
- Talos Linux ISO uploaded to Proxmox
- `talosctl` CLI installed on management machine
- `kubectl` installed on management machine

## Network Architecture

### IP Allocation Scheme

| Role | IP Range | Purpose |
|------|----------|---------|
| VIP | 10.x.x.100 | Kubernetes API endpoint |
| Control Plane | 10.x.x.101-103 | Master nodes |
| Workers | 10.x.x.111-113 | Worker nodes |
| Gateway | 10.x.x.1 | Network gateway |

### Network Configuration

- **Subnet**: /24
- **Interface**: ens18 (Proxmox default)
- **DNS**: 8.8.8.8, 1.1.1.1
- **Connectivity**: Static IP addressing

## Installation Process

### Phase 1: Generate Cluster Configuration

```bash
# Create configuration directory
mkdir -p ./talos-config

# Generate base configs
talosctl gen config my-cluster https://10.x.x.100:6443 \
  --output-dir ./talos-config
```

This creates:
- `controlplane.yaml` - Control plane node configuration
- `worker.yaml` - Worker node configuration  
- `talosconfig` - Client configuration for talosctl

### Phase 2: Configure Network Settings

Edit both `controlplane.yaml` and `worker.yaml` to add network configuration.

Find the line `network: {}` and replace with:

```yaml
network:
  interfaces:
    - interface: ens18  # CRITICAL: Use ens18 for Proxmox VMs, not eth0
      routes:
        - network: 0.0.0.0/0
          gateway: 10.x.x.1
  nameservers:
    - 8.8.8.8
    - 1.1.1.1
```

**Important**: Do NOT add IP addresses in the base config - these will be added per-node during application.

### Phase 3: Deploy Control Plane Nodes

For each control plane node:

1. Create VM in Proxmox with Talos ISO
2. Start the VM and note its DHCP-assigned IP
3. Apply configuration with static IP:

```bash
# Control Plane Node 1
talosctl apply-config --insecure \
  --nodes <DHCP-IP> \
  --file ./talos-config/controlplane.yaml \
  --config-patch '[{"op":"add","path":"/machine/network/interfaces/0/addresses","value":["10.x.x.101/24"]}]'

# Control Plane Node 2
talosctl apply-config --insecure \
  --nodes <DHCP-IP> \
  --file ./talos-config/controlplane.yaml \
  --config-patch '[{"op":"add","path":"/machine/network/interfaces/0/addresses","value":["10.x.x.102/24"]}]'

# Control Plane Node 3
talosctl apply-config --insecure \
  --nodes <DHCP-IP> \
  --file ./talos-config/controlplane.yaml \
  --config-patch '[{"op":"add","path":"/machine/network/interfaces/0/addresses","value":["10.x.x.103/24"]}]'
```

Wait 1-2 minutes after each application for the node to reconfigure.

### Phase 4: Deploy Worker Nodes

Repeat the process for worker nodes:

```bash
# Worker Node 1
talosctl apply-config --insecure \
  --nodes <DHCP-IP> \
  --file ./talos-config/worker.yaml \
  --config-patch '[{"op":"add","path":"/machine/network/interfaces/0/addresses","value":["10.x.x.111/24"]}]'

# Worker Node 2
talosctl apply-config --insecure \
  --nodes <DHCP-IP> \
  --file ./talos-config/worker.yaml \
  --config-patch '[{"op":"add","path":"/machine/network/interfaces/0/addresses","value":["10.x.x.112/24"]}]'

# Worker Node 3
talosctl apply-config --insecure \
  --nodes <DHCP-IP> \
  --file ./talos-config/worker.yaml \
  --config-patch '[{"op":"add","path":"/machine/network/interfaces/0/addresses","value":["10.x.x.113/24"]}]'
```

### Phase 5: Configure talosctl Client

```bash
# Set endpoints to all control plane nodes
talosctl --talosconfig=./talos-config/talosconfig \
  config endpoint 10.x.x.101 10.x.x.102 10.x.x.103

# Set nodes
talosctl --talosconfig=./talos-config/talosconfig \
  config node 10.x.x.101 10.x.x.102 10.x.x.103

# Merge into default config
talosctl config merge ./talos-config/talosconfig
```

### Phase 6: Bootstrap the Cluster

**CRITICAL**: Only run bootstrap ONCE on ONE control plane node.

```bash
talosctl bootstrap --nodes 10.x.x.101
```

Wait 2-3 minutes for the cluster to initialize.

### Phase 7: Configure High Availability

Deploy kube-vip for VIP management:

```bash
# Temporarily point kubectl to a control plane node
kubectl config set-cluster my-cluster --server=https://10.x.x.101:6443

# Apply RBAC
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml

# Create kube-vip DaemonSet (see kube-vip-config.yaml in repo)
kubectl apply -f kube-vip-daemonset.yaml

# Wait for VIP to come online (30-60 seconds)
ping 10.x.x.100

# Update kubeconfig to use VIP
kubectl config set-cluster my-cluster --server=https://10.x.x.100:6443
```

### Phase 8: Retrieve kubeconfig

```bash
# Generate kubeconfig
talosctl kubeconfig

# Verify cluster access
kubectl get nodes
```

## Verification

### Check Cluster Health

```bash
# All nodes should show Ready
kubectl get nodes

# All system pods should be Running
kubectl get pods -A

# Check etcd cluster
talosctl etcd members

# Verify services
talosctl service --nodes 10.x.x.101
```

Expected output:
```
NAME            STATUS   ROLES           AGE   VERSION
talos-xxx-xxx   Ready    control-plane   10m   v1.34.0
talos-xxx-xxx   Ready    control-plane   10m   v1.34.0
talos-xxx-xxx   Ready    control-plane   10m   v1.34.0
talos-xxx-xxx   Ready    <none>          10m   v1.34.0
talos-xxx-xxx   Ready    <none>          10m   v1.34.0
talos-xxx-xxx   Ready    <none>          10m   v1.34.0
```

### Validate HA Configuration

Test VIP failover:
1. Stop one control plane node in Proxmox
2. Verify VIP remains accessible
3. Kubernetes API continues to respond

## Key Learnings and Gotchas

### Interface Naming
**Critical Issue**: Proxmox VMs use `ens18` as the network interface, not `eth0`.

Symptoms if wrong:
- Static IP configuration appears in machine config
- Node continues using DHCP
- Reboot doesn't fix the issue

Solution: Always use `interface: ens18` in network configuration for Proxmox VMs.

### Bootstrap Process
**Only run `talosctl bootstrap` once** on a single control plane node. Running it multiple times or on multiple nodes will break the etcd cluster.

### Configuration Application
Two methods exist:
- `talosctl apply-config`: Full configuration replacement
- `talosctl patch machineconfig`: Incremental updates

Use `apply-config` during initial setup and `patch` for subsequent changes.

### VIP Management
The VIP (10.x.x.100) is not automatically created by Talos. It requires kube-vip or similar solution. Without it, the cluster works but lacks HA for API access.

## Troubleshooting

### Node Won't Join Cluster

```bash
# Check node logs
talosctl --nodes 10.x.x.10X dmesg

# Verify etcd status
talosctl --nodes 10.x.x.10X service etcd status

# Check network connectivity
talosctl --nodes 10.x.x.10X get addressstatuses
```

### Static IP Not Applying

```bash
# Verify machine config
talosctl get machineconfig -o yaml | grep -A 15 "network:"

# Check if interface name is correct
talosctl get links

# Manually patch if needed
talosctl patch machineconfig --patch '[...]'
```

### VIP Not Responding

```bash
# Check kube-vip pods
kubectl get pods -n kube-system -l name=kube-vip-ds

# View logs
kubectl logs -n kube-system -l name=kube-vip-ds

# Verify leader election
kubectl logs -n kube-system -l name=kube-vip-ds | grep -i leader
```

## Maintenance

### Upgrading Talos

```bash
talosctl upgrade --nodes 10.x.x.101,10.x.x.102,10.x.x.103 \
  --image ghcr.io/siderolabs/installer:v1.X.X
```

### Upgrading Kubernetes

```bash
talosctl upgrade-k8s --to 1.XX.0
```

### Adding Worker Nodes

1. Create new VM in Proxmox
2. Apply worker configuration with new IP
3. Node automatically joins cluster

### Removing Nodes

```bash
# Drain node
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Remove from cluster
kubectl delete node <node-name>

# Reset node (if reusing)
talosctl reset --nodes 10.x.x.XXX --graceful=false
```

## Security Considerations

### Talos Security Model

- **No SSH access**: API-only management
- **Immutable OS**: Read-only root filesystem
- **Minimal attack surface**: No shell, no package manager
- **API authentication**: Certificate-based mutual TLS

### Network Security

- Control plane ports (6443) exposed only to VIP
- Worker nodes communicate via pod network (Flannel)
- etcd peer communication encrypted

### Configuration Management

- Keep `talosconfig` secure - contains cluster certificates
- Store machine configs in version control (without secrets)
- Rotate certificates periodically

## Next Steps

Recommended additions to complete the cluster:

1. **Persistent Storage**
   - Longhorn for distributed block storage
   - NFS provisioner for shared storage
   - Local path provisioner for node-local storage

2. **Ingress Controller**
   - Traefik or Nginx Ingress
   - Cert-manager for TLS automation

3. **Observability**
   - Prometheus + Grafana for metrics
   - Loki for log aggregation
   - Alertmanager for notifications

4. **GitOps**
   - FluxCD or ArgoCD for declarative deployments
   - Automated sync from Git repositories

5. **Service Mesh** (optional)
   - Istio or Linkerd for advanced traffic management

## Resources

- [Talos Linux Documentation](https://www.talos.dev/latest/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kube-vip Documentation](https://kube-vip.io/)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)

## License

This documentation is provided as-is for educational purposes.

---

**Cluster Status**: Production Ready  
**Last Updated**: October 2025  
**Maintained By**: Philip John Faraon
