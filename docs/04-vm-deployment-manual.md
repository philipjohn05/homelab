# Manual VM Deployment Guide

## Overview

This guide documents the manual deployment of 6 Rocky Linux VMs (3 masters, 3 workers) for Kubernetes cluster setup using Proxmox VE.

## Prerequisites

- Proxmox VE 8.x installed and configured
- Rocky Linux template created (see `02-vm-template-creation.md`)
- Cloud-init configuration file ready (see `03-cloud-init-configuration.md`)
- SSH key configured in cloud-init user config

## Network Planning

### IP Allocation

| Hostname       | VM ID | IP Address    | Role   | CPU | RAM (GB) | Disk (GB) |
|----------------|-------|---------------|--------|-----|----------|-----------|
| k8s-master-01  | 301   | 10.0.0.11/24  | Master | 4   | 8        | 50        |
| k8s-master-02  | 302   | 10.0.0.12/24  | Master | 4   | 8        | 50        |
| k8s-master-03  | 303   | 10.0.0.13/24  | Master | 4   | 8        | 50        |
| k8s-worker-01  | 401   | 10.0.0.21/24  | Worker | 4   | 12       | 50        |
| k8s-worker-02  | 402   | 10.0.0.22/24  | Worker | 4   | 10       | 50        |
| k8s-worker-03  | 403   | 10.0.0.23/24  | Worker | 4   | 8        | 50        |

**Network Configuration:**
- Network: 10.0.0.0/24
- Gateway: 10.0.0.1
- DNS: 1.1.1.1

## Deployment Process

### Step 1: Clone Template for Master Nodes

SSH to Proxmox host:
```bash
ssh root@YOUR-PROXMOX-IP

# Deploy master nodes
for i in 1 2 3; do
  echo "Creating k8s-master-0$i..."
  qm clone TEMPLATE_ID 30$i --name k8s-master-0$i --full --storage local-lvm
  qm set 30$i --cores 4 --memory 8192
  qm set 30$i --cicustom "user=local:snippets/user-config.yaml"
  qm set 30$i --ipconfig0 "ip=10.0.0.1$i/24,gw=10.0.0.1"
  qm set 30$i --nameserver 1.1.1.1
  qm cloudinit update 30$i
done
```
