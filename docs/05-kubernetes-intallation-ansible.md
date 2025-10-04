# Kubernetes Installation with Ansible and RKE2

## Overview

This guide documents the automated installation of a 3-node HA Kubernetes cluster using Ansible and RKE2 on Rocky Linux 9.6 VMs.

## Prerequisites

- 6 Rocky Linux VMs deployed (3 masters, 3 workers)
- SSH key-based authentication configured
- Ansible installed on management workstation
- All nodes accessible via SSH

## Architecture
```bash
Control Plane (HA):
├── k8s-master-01 (10.0.0.11) - Primary control plane
├── k8s-master-02 (10.0.0.12) - Secondary control plane
└── k8s-master-03 (10.0.0.13) - Tertiary control plane
Workers:
├── k8s-worker-01 (10.0.0.21) - 12GB RAM
├── k8s-worker-02 (10.0.0.22) - 10GB RAM
└── k8s-worker-03 (10.0.0.23) - 8GB RAM
```
## Part 1: Ansible Setup

### Install Ansible

On your management workstation (MacBook/Linux):
```bash
# macOS
brew install ansible

# Verify installation
ansible --version
```

Create Project Structure

```bash
cd ~/kubernetes-homelab

# Create Ansible directories
mkdir -p ansible/{inventory,playbooks,roles,group_vars,host_vars}

# Directory structure
ansible/
├── inventory/
│   └── hosts.ini
├── playbooks/
│   ├── 01-prepare-nodes.yml
│   ├── 02-install-rke2-masters.yml
│   ├── 03-install-rke2-workers.yml
│   └── 04-configure-firewall.yml
├── roles/
├── group_vars/
│   └── all.yml
└── host_vars/
```

Create Ansible Configuration

File: ansible/ansible.cfg
```
[defaults]
host_key_checking = False
inventory = inventory/hosts.ini
remote_user = YOUR_SSH_USER
retry_files_enabled = False
```
Replace YOUR_SSH_USER with your configured username.

Create Inventory File

File: ansible/inventory/hosts.ini
```
[masters]
k8s-master-01 ansible_host=10.0.0.11 ansible_user=YOUR_USER
k8s-master-02 ansible_host=10.0.0.12 ansible_user=YOUR_USER
k8s-master-03 ansible_host=10.0.0.13 ansible_user=YOUR_USER

[workers]
k8s-worker-01 ansible_host=10.0.0.21 ansible_user=YOUR_USER
k8s-worker-02 ansible_host=10.0.0.22 ansible_user=YOUR_USER
k8s-worker-03 ansible_host=10.0.0.23 ansible_user=YOUR_USER

[k8s_cluster:children]
masters
workers

[k8s_cluster:vars]
ansible_python_interpreter=/usr/bin/python3
```

Replace:

IP addresses with your actual network

YOUR_USER with your SSH username

Create Global Variables

File: ansible/group_vars/all.yml
```
---
# Cluster configuration
cluster_name: homelab-k8s
kubernetes_version: v1.28

# Network configuration
cluster_cidr: 10.42.0.0/16
service_cidr: 10.43.0.0/16
cluster_dns: 10.43.0.10

# RKE2 configuration
rke2_version: v1.28.6+rke2r1

# First master IP (for cluster join)
primary_master: 10.0.0.11

# System configuration
timezone: YOUR_TIMEZONE
```

Test Ansible Connectivity

```
cd ~/kubernetes-homelab/ansible

# Test connection to all nodes
ansible -i inventory/hosts.ini all -m ping
```

Expected output:
```
k8s-master-01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
k8s-master-02 | SUCCESS => { ... }
...
```

Troubleshooting Ansible Connection

SSH key not found:
```bash
# Verify SSH agent has your key
ssh-add -l

# Add key if missing
ssh-add ~/.ssh/id_ed25519
```

Python not found on remote hosts:
```
# Test if Python 3 exists
ansible -i inventory/hosts.ini all -m raw -a "which python3"
```

Permission denied:
```
# Verify user has sudo NOPASSWD configured on all nodes
ssh YOUR_USER@10.0.0.11 "sudo whoami"
```

Part 2: RKE2 Firewall Configuration

Required Ports

RKE2 requires specific firewall ports to be open for cluster communication.

Master Nodes
