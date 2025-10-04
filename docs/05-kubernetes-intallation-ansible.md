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

