# 🏠 Kubernetes Homelab

## 📖 Introduction

This repository contains all of the configuration and documentation of my Kubernetes homelab.

The purpose of my homelab is to **learn production patterns at scale** and to have fun experimenting with cloud-native technologies. As someone working with Kubernetes professionally, my homelab is where I can break things, learn from mistakes, and understand infrastructure deeply - without the pressure of production incidents.

Self-hosting applications forces me to think about the entire lifecycle: **backup strategies, disaster recovery, security hardening, GitOps workflows, and operational excellence**. It's one thing to deploy an app - it's another to maintain it reliably and recover from failures.

### Key Principles

- **Everything is code** - Infrastructure, applications, and configurations
- **Zero secrets in Git** - All sensitive data in Azure Key Vault
- **Immutable infrastructure** - Talos Linux enforces declarative configuration
- **Full automation** - FluxCD handles deployments from Git
- **10-minute recovery** - Entire cluster can be rebuilt from this repo

---

## 🏗️ Cluster Provisioning & Architecture

I use **Talos Linux** to provision my Kubernetes nodes. Talos is minimal, immutable, and API-driven (no SSH access). It provides production-grade security out of the box and eliminates configuration drift entirely.

### Current Architecture

I run a **single 6-node cluster** with high availability:

| **Cluster** | **Description** |
|-------------|-----------------|
| **lothbrok** | Production cluster. 3 control plane nodes (HA with kube-vip) + 3 worker nodes. Runs all infrastructure components and applications. Fully provisioned from code via FluxCD GitOps. Can be destroyed and rebuilt in 10 minutes. |

### Infrastructure Components

**Control Plane:**
- 3 nodes for high availability
- kube-vip provides virtual IP for API server
- etcd cluster tolerates single node failure
- Any control plane node can fail - cluster stays operational

**Workers:**
- 3 nodes for application workloads
- Dedicated to running pods
- Resource isolation from control plane

**Network:**
- Flannel CNI (via Talos)
- MetalLB for LoadBalancer services (L2 mode)
- 4 segmented IP pools for different workload types

### GitOps Architecture

**3-Phase Deployment Pipeline:**

Phase 1: infrastructure
↓ (deploys controllers)
Phase 2: infrastructure-secrets
↓ (syncs from Azure Key Vault)
Phase 3: infrastructure-config
↓ (applies configs with substitution)
Result: Fully automated, zero manual intervention

**Why 3 phases?**
- Prevents race conditions (configs needing secrets that don't exist yet)
- Proper dependency ordering (operators before CRDs)
- Clean separation of concerns (controllers vs. secrets vs. configs)

---

## 💻 Hardware

### Nodes

Running on **Proxmox VE 8.x** as the hypervisor layer:

| Node | Role | vCPU | RAM | Disk | Purpose |
|------|------|------|-----|------|---------|
| talos-cp-01 | Control Plane | 4 | 6 GB | 32 GB | etcd, kube-apiserver, scheduler, controller-manager |
| talos-cp-02 | Control Plane | 4 | 6 GB | 32 GB | etcd, kube-apiserver, scheduler, controller-manager |
| talos-cp-03 | Control Plane | 4 | 6 GB | 32 GB | etcd, kube-apiserver, scheduler, controller-manager |
| talos-worker-01 | Worker | 4 | 8 GB | 100 GB | Application workloads |
| talos-worker-02 | Worker | 4 | 8 GB | 100 GB | Application workloads |
| talos-worker-03 | Worker | 4 | 8 GB | 100 GB | Application workloads |

**Physical Hardware:**
- Proxmox Host: ThinkCentre M90T, 48GM RAM & GPU 1660 Super
- Storage: local storage

---

## 🚀 Installed Apps & Tools

### 📱 End User Applications

| Logo | Name | Description |
|------|------|-------------|
| <img width="32" src="https://avatars.githubusercontent.com/u/134059324"> | [Linkding](https://github.com/linkding-io/linkding) | Self-hosted bookmark manager with tagging and full-text search |

### 🔧 Infrastructure

Everything needed to run the cluster and deploy applications:

| Logo | Name | Description |
|------|------|-------------|
| <img width="32" src="https://avatars.githubusercontent.com/u/47601702"> | [Talos Linux](https://www.talos.dev/) | Immutable, API-driven Kubernetes OS. No SSH, minimal attack surface, production-grade security |
| <img width="32" src="https://avatars.githubusercontent.com/u/52158677"> | [FluxCD](https://fluxcd.io/) | GitOps operator. Watches Git, applies changes automatically. 3-phase pipeline for dependency management |
| <img width="32" src="https://external-secrets.io/latest/pictures/eso-logo-large.png"> | [External Secrets Operator](https://external-secrets.io/) | Syncs secrets from Azure Key Vault to Kubernetes. Zero secrets in Git. ~2,880 API calls/month = $0.01 |
| <img width="32" src="https://avatars.githubusercontent.com/u/60239468"> | [MetalLB](https://metallb.universe.tf/) | LoadBalancer implementation for bare-metal. L2 mode. 4 IP pools: ingress, services, database, reserved |
| <img width="32" src="https://avatars.githubusercontent.com/u/1412239"> | [Traefik](https://traefik.io/) | Cloud-native ingress controller. Automatic routing based on Ingress resources. Gets IP from MetalLB |
| <img width="32" src="https://avatars.githubusercontent.com/u/314135"> | [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/) | Zero-trust access without port forwarding. Secure tunnel from cluster to Cloudflare edge |
| <img width="32" src="https://avatars.githubusercontent.com/u/47602533"> | [SOPS](https://github.com/mozilla/sops) | Encrypted secrets in Git. Used for non-dynamic sensitive configs |

### 📊 Monitoring (Coming Soon)

| Logo | Name | Description |
|------|------|-------------|
| <img width="32" src="https://avatars.githubusercontent.com/u/3380462"> | [Prometheus](https://prometheus.io/) | Metrics collection and alerting |
| <img width="32" src="https://avatars.githubusercontent.com/u/7195757"> | [Grafana](https://grafana.com/) | Dashboards and visualization |

### 💾 Data (Coming Soon)

| Logo | Name | Description |
|------|------|-------------|
| <img width="32" src="https://avatars.githubusercontent.com/u/69524162"> | [CloudNativePG](https://cloudnative-pg.io/) | PostgreSQL operator for Kubernetes. Production-grade database management |

---
