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

Replace TEMPLATE_ID with your template VM ID (example: 9000)

Step 2: Clone Template for Worker Nodes
```bash
# Deploy worker 01 (12GB RAM)
qm clone TEMPLATE_ID 401 --name k8s-worker-01 --full --storage local-lvm
qm set 401 --cores 4 --memory 12288
qm set 401 --cicustom "user=local:snippets/user-config.yaml"
qm set 401 --ipconfig0 "ip=10.0.0.21/24,gw=10.0.0.1"
qm set 401 --nameserver 1.1.1.1
qm cloudinit update 401

# Deploy worker 02 (10GB RAM)
qm clone TEMPLATE_ID 402 --name k8s-worker-02 --full --storage local-lvm
qm set 402 --cores 4 --memory 10240
qm set 402 --cicustom "user=local:snippets/user-config.yaml"
qm set 402 --ipconfig0 "ip=10.0.0.22/24,gw=10.0.0.1"
qm set 402 --nameserver 1.1.1.1
qm cloudinit update 402

# Deploy worker 03 (8GB RAM)
qm clone TEMPLATE_ID 403 --name k8s-worker-03 --full --storage local-lvm
qm set 403 --cores 4 --memory 8192
qm set 403 --cicustom "user=local:snippets/user-config.yaml"
qm set 403 --ipconfig0 "ip=10.0.0.23/24,gw=10.0.0.1"
qm set 403 --nameserver 1.1.1.1
qm cloudinit update 403
```

Step 3: Start All VMs

```bash
# Start all VMs
echo "Starting all VMs..."
for vmid in 301 302 303 401 402 403; do
  qm start $vmid
done

# Wait for boot and cloud-init
echo "Waiting 90 seconds for cloud-init to complete..."
sleep 90

# Check VM status
qm list
```

Step 4: Verify VMs are Running
```bash
# Check all VMs are running
qm list | grep -E "301|302|303|401|402|403"
```

Expected output:
```bash
301 k8s-master-01  running  8192   50.00
302 k8s-master-02  running  8192   50.00
303 k8s-master-03  running  8192   50.00
401 k8s-worker-01  running  12288  50.00
402 k8s-worker-02  running  10240  50.00
403 k8s-worker-03  running  8192   50.00
```

Post-Deployment Configuration

Verify SSH Access

From your workstation:

```bash
# Test SSH to all nodes
for ip in 10.0.0.{11..13} 10.0.0.{21..23}; do
  echo -n "Testing $ip: "
  ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no USER@$ip "hostname" 2>/dev/null && echo "OK" || echo "FAILED"
done
```

Replace USER with your configured username (example: rocky)

Expected output:
```bash
Testing 10.0.0.11: k8s-master-01 OK
Testing 10.0.0.12: k8s-master-02 OK
Testing 10.0.0.13: k8s-master-03 OK
Testing 10.0.0.21: k8s-worker-01 OK
Testing 10.0.0.22: k8s-worker-02 OK
Testing 10.0.0.23: k8s-worker-03 OK
```

Set Static IPs (If Cloud-Init Assigned DHCP)

If VMs received DHCP addresses instead of static IPs, configure manually:

```bash
# SSH to each VM and set static IP
ssh USER@CURRENT-DHCP-IP

# Find network connection name
nmcli con show

# Set static IP (replace connection name and IP as needed)
sudo nmcli con mod "Wired connection 1" ipv4.addresses 10.0.0.11/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 10.0.0.1
sudo nmcli con mod "Wired connection 1" ipv4.dns 1.1.1.1
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con up "Wired connection 1"

# Disable cloud-init network management
sudo bash -c 'cat > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg << EOF
network: {config: disabled}
EOF'
```

Repeat for all VMs with their respective IP addresses.

Verify Cloud-Init Completion

SSH to each node:
```bash
ssh USER@10.0.0.11

# Check cloud-init status
cloud-init status

# Should show: status: done

# Check system configuration
hostname            # Should show: k8s-master-01
getenforce          # Should show: Enforcing
free -h             # Check memory
df -h               # Check disk space
```

Troubleshooting

VMs Not Starting

Check VM console in Proxmox UI:
```bash
1. Select VM in left sidebar
2. Click Console
3. Look for boot errors
```

Check VM logs:
```bash
# On Proxmox host
journalctl -u pve* --since "10 minutes ago" | grep -i error
```

Cloud-Init Not Running

Check cloud-init logs:
```bash
# On the VM
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

Force cloud-init to re-run:
```bash
sudo cloud-init clean
sudo reboot
```

SSH Access Fails

Verify SSH service is running:
```bash
# Check from Proxmox console
systemctl status sshd
```

Check SSH key was installed:
```bash
cat ~/.ssh/authorized_keys
# Should show your public key
```

Verify password authentication is disabled:
```bash
sudo sshd -T | grep passwordauthentication
# Should show: passwordauthentication no
```

Static IP Not Applied

Check network configuration:
```bash
# View current IP
ip addr show

# Check NetworkManager connection
nmcli con show

# Restart network
sudo nmcli con down "Wired connection 1"
sudo nmcli con up "Wired connection 1"
```

Storage Considerations

Disk Space Requirements

Total storage needed:

Master nodes: 3 × 50GB = 150GB

Worker nodes: 3 × 50GB = 150GB

Total: 300GB minimum


Verify available storage:

