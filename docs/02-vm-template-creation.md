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
### Step 4: SELinux SSH Fix

- After SELinux relabel, SSH password authentication is blocked. Install custom policy:

```bash
cat > /tmp/sshd_shadow_fix.te << 'EOF'
module sshd_shadow_fix 1.0;

require {
    type sshd_t;
    type shadow_t;
    class file { read getattr open };
}

allow sshd_t shadow_t:file { read getattr open };
EOF

checkmodule -M -m -o /tmp/sshd_shadow_fix.mod /tmp/sshd_shadow_fix.te
semodule_package -o /tmp/sshd_shadow_fix.pp -m /tmp/sshd_shadow_fix.mod
semodule -i /tmp/sshd_shadow_fix.pp
rm -f /tmp/sshd_shadow_fix.*

# Verify installed
semodule -l | grep sshd_shadow
```

### Step 5: Remove Users

- Remove any users created during setup (cloud-init will create them):

```bash
# Remove regular users if any exist
userdel -r rocky 2>/dev/null || true
userdel -r admin 2>/dev/null || true

# Verify only system users remain
awk -F: '$3 >= 1000 {print $1}' /etc/passwd
# Should show nothing
```

### Step 6: System CleanUp

```bash
# Clean cloud-init
cloud-init clean --logs --seed

# Remove SSH host keys (regenerated on clone)
rm -f /etc/ssh/ssh_host_*

# Remove machine-id (regenerated on clone)
truncate -s 0 /etc/machine-id

# Clean logs
logrotate -f /etc/logrotate.conf
journalctl --vacuum-time=1s
cat /dev/null > /var/log/audit/audit.log
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/lastlog

# Clean package cache
dnf clean all

# Clean bash history
history -c
cat /dev/null > ~/.bash_history
```

### Step 7: SELinux Relabel
```bash
# Schedule filesystem relabel
touch /.autorelabel

# Reboot
reboot

# System will:
# - Boot into relabel mode
# - Relabel all files (10-20 minutes)
# - Automatically reboot when complete
```

### Step 8: Post-Relabel Verification
```bash
# Check SELinux enforcing
getenforce
# Output: Enforcing

# Check no relabel file remains
ls /.autorelabel
# Output: No such file or directory

# Check SELinux policy installed
semodule -l | grep sshd_shadow
# Output: sshd_shadow_fix

# Final cleanup
history -c
shutdown -h now
```

### Step 9: Convert to Template
- In Proxmox Web UI:
```bash
1. Right-click VM → Convert to Template
2. Confirm: Yes
3. VM icon changes to template icon
```

### Add CloudInit drive:
```bash
1. Select template → Hardware tab
2. Click: Add → CloudInit Drive
3. Storage: local-lvm
4. Click: Add
5. Verify: CloudInit Drive (ide2) appears in hardware list
```
## Important Security Notes

**Before using this configuration:**

1. Replace placeholder SSH keys with your actual public key
2. Never commit private keys to git repositories
3. Generate your SSH key pair:
```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
```


### Cloud-Init Configuration

- Create Custom User Config
- On Proxmox host:
```bash
# Create snippets directory
mkdir -p /var/lib/vz/snippets

# Create user configuration
cat > /var/lib/vz/snippets/user-config.yaml << 'EOF'
#cloud-config
users:
  - name: rocky
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-public-key-here

ssh_pwauth: false
disable_root: true

write_files:
  - path: /etc/ssh/sshd_config.d/50-cloud-init.conf
    permissions: '0644'
    owner: root:root
    content: |
      PasswordAuthentication no
      PubkeyAuthentication yes
      PermitRootLogin no

runcmd:
  - systemctl restart sshd
EOF
```

### Replace ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... with your actual SSH public key from:
```bash
# On your workstation
cat ~/.ssh/id_ed25519.pub
```

### Using Template
- Clone VM via Command Line
