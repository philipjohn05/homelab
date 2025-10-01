# VM Template Creation Guide

## Overview

This guide documents the creation of a Rocky Linux 9.6 VM template for Kubernetes node deployment. The template is configured with cloud-init, SELinux enforcing, and SSH key authentication.

## Template Specifications

- **Operating System**: Rocky Linux 9.6 (Blue Onyx)
- **Kernel**: 5.14.0-570.42.2.el9_6.x86_64
- **CPU**: 2 cores (adjustable on clone)
- **RAM**: 4GB (adjustable on clone)
- **Disk**: 32GB (expandable on clone)
- **Storage**: NVMe (local-lvm or vg-nvme-storage)

## Pre-installed Components

- **Cloud-init**: Version 24.4 with NoCloud datasource for Proxmox
- **qemu-guest-agent**: For Proxmox integration
- **Security**: SELinux enforcing, firewalld enabled
- **Automation**: Automatic security updates via dnf-automatic
- **Time sync**: chrony configured
- **Kubernetes prep**: Kernel modules and sysctl parameters configured

## Prerequisites

- Proxmox VE 8.x installed and configured
- Rocky Linux 9.6 minimal ISO uploaded to Proxmox
- Network connectivity (192.168.0.0/24)
- SSH key pair generated on management workstation

## Template Creation Process

### Step 1: Create Base VM
```bash
# In Proxmox Web UI
# 1. Create New VM
#    - VM ID: 100 (or available ID)
#    - Name: rocky9-template
#    - ISO: Rocky-9.x-x86_64-minimal.iso
#    - Disk: 32GB
#    - CPU: 2 cores
#    - RAM: 4GB
#    - Network: vmbr0

# 2. Start VM and complete Rocky Linux installation
#    - Minimal installation
#    - Set root password
#    - Do NOT create regular users yet
```

### Step 2: Configure Cloud-Init

- SSH to the VM and run:

```bash
# Install cloud-init packages
dnf install -y cloud-init cloud-utils-growpart qemu-guest-agent

# Configure Proxmox datasource
cat > /etc/cloud/cloud.cfg.d/99_pve.cfg <<'EOF'
datasource_list: [NoCloud, ConfigDrive]
EOF

# Configure disk resize
cat > /etc/cloud/cloud.cfg.d/90_resize.cfg <<'EOF'
growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false

resize_rootfs: true
EOF

# Disable network config (NetworkManager handles it)
cat > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg <<'EOF'
network: {config: disabled}
EOF

# Enable services
systemctl enable cloud-init-local.service
systemctl enable cloud-init.service
systemctl enable cloud-config.service
systemctl enable cloud-final.service
systemctl enable qemu-guest-agent
systemctl enable NetworkManager
```

### Step 3. Security Hardenig

```bash
# Update system
dnf update -y

# Install security tools
dnf install -y \
    dnf-automatic \
    firewalld \
    audit \
    policycoreutils-python-utils \
    chrony

# Configure automatic security updates
cat > /etc/dnf/automatic.conf <<'EOF'
[commands]
upgrade_type = security
download_updates = yes
apply_updates = yes
EOF

systemctl enable --now dnf-automatic.timer

# Configure firewall
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --permanent --add-port=179/tcp
firewall-cmd --permanent --add-port=4789/udp
firewall-cmd --reload

# Configure SELinux
setenforce 1
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
setsebool -P ssh_sysadm_login on
setsebool -P allow_ssh_keysign on

# Kernel parameters for Kubernetes
cat > /etc/sysctl.d/99-kubernetes.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF

# Load kernel modules
cat > /etc/modules-load.d/kubernetes.conf <<'EOF'
overlay
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

modprobe overlay
modprobe br_netfilter
sysctl --system

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure time sync
systemctl enable --now chronyd
```

