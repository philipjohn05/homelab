# Proxmox VE Installation Guide

## Important Notes

**Network Configuration:**

All IP addresses in this documentation are examples. Replace with your actual network configuration:

- Network range: Adjust to match your home network
- Gateway IP: Use your router's IP address
- DNS servers: Use your preferred DNS (examples: 1.1.1.1, 8.8.8.8, 9.9.9.9)
- Host IPs: Assign based on your network plan

**Example network configuration shown:**

Network: 10.0.0.0/24
Gateway: 10.0.0.1
Proxmox: 10.0.0.100
Masters: 10.0.0.11-13
Workers: 10.0.0.21-23

Adjust these values for your environment.

## Overview

This guide documents the installation and configuration of Proxmox VE 8.x on a Lenovo ThinkCentre M90t for use as a Kubernetes homelab hypervisor.

## Hardware Specifications

### Server Details

- **Model**: Lenovo ThinkCentre M90t
- **CPU**: Intel Core i7 (8+ cores)
- **RAM**: 48GB DDR4
- **Storage**: 
  - NVMe 0: 500GB (Proxmox + primary VM storage)
  - NVMe 1: 500GB (additional VM storage)
- **Network**: Gigabit Ethernet (1000 Mbps)
- **Graphics**: 6GB Intel Graphics

### BIOS Configuration

Required BIOS settings for virtualization:

Security Tab:

Secure Boot: Disabled

Advanced Tab - CPU Configuration:

Intel Virtualization Technology (VT-x): Enabled
Intel VT-d Feature: Enabled
Intel Hyper-Threading: Enabled

Boot Tab:

Boot Mode: UEFI
Fast Boot: Disabled

Access BIOS: Press F1 during startup

## Pre-Installation

### Download Proxmox VE

URL: https://www.proxmox.com/en/downloads
File: proxmox-ve_8.x.iso (approximately 1.2GB)
Version: 8.x (latest stable)

### Create Bootable USB

**On macOS:**
```bash
# Find USB device
diskutil list

# Unmount USB (replace diskX with your USB device)
diskutil unmountDisk /dev/diskX

# Write ISO to USB
sudo dd if=proxmox-ve_8.x.iso of=/dev/rdiskX bs=1m

# Eject
diskutil eject /dev/diskX
```

# Find USB device
lsblk

# Write ISO (replace sdX with your USB device)
sudo dd if=proxmox-ve_8.x.iso of=/dev/sdX bs=4M status=progress

# Sync
sync

On Windows:
Use Rufus utility:

1. Download Rufus from https://rufus.ie
2. Select Proxmox ISO
3. Partition scheme: GPT
4. Target system: UEFI
5. Click START

Installation Process
Boot from USB

1. Insert Proxmox USB drive
2. Power on server
3. Press F12 for boot menu (Lenovo)
4. Select USB drive
5. Wait for Proxmox boot screen

Installation Wizard
Select Installation:

Proxmox VE Boot Menu
→ Install Proxmox VE (Graphical)

Accept EULA:

Read license agreement
Click: I agree

Target Disk:

Target Harddisk: /dev/nvme0n1 (500GB)

WARNING: This will erase all data on the disk

Filesystem: ext4

Location and Time:

Country: Your Country
Time zone: Your Timezone
Keyboard Layout: Your Layout

Example:
  Country: Australia
  Time zone: Australia/Hobart
  Keyboard: en-us

Administrator Password:

Password: [Create strong password]
Confirm: [Re-enter password]
Email: your-email@example.com

Store password securely in password manager

Network Configuration:

Management Interface: eno2 (or auto-detected)
Hostname (FQDN): pve-homelab.local
IP Address (CIDR): 10.0.0.100/24
Gateway: 10.0.0.1
DNS Server: 1.1.1.1

Network: 10.0.0.0/24

Installation Summary:

Verify all settings:
- Target disk: /dev/nvme0n1
- Hostname: pve-homelab.local
- IP: 10.0.0.100/24
- Gateway: 10.0.0.1

Click: Install

Installation takes 5-15 minutes.

First Boot

1. System reboots automatically
2. Remove USB drive when prompted
3. Login screen appears showing:
   https://10.0.0.100:8006

Post-Installation Configuration
Access Web Interface
From your workstation:

1. Open web browser
2. Navigate to: https://10.0.0.100:8006
3. Accept SSL certificate warning
4. Login:
   - Username: root
   - Password: [installation password]
   - Realm: Linux PAM standard authentication
5. Dismiss subscription notice (OK for home use)

Update System
Via Web Interface:

1. Select: pve-homelab
2. Click: Updates
3. Click: Refresh
4. Click: Upgrade

Via Shell:
```bash
# Click Shell button in web interface

# Update package lists
apt update

# Upgrade packages
apt upgrade -y

# Distribution upgrade
apt dist-upgrade -y

# Clean up
apt autoremove -y
apt autoclean

Configure Repositories
Remove enterprise repositories (require paid subscription):
```

```bash
# Remove misconfigured .sources files
rm -f /etc/apt/sources.list.d/*.sources

# Create Debian base repositories
cat > /etc/apt/sources.list <<'EOF'
# Debian Bookworm (Debian 12)
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware

# Debian Security
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# Create Proxmox no-subscription repository
cat > /etc/apt/sources.list.d/pve-no-subscription.list <<'EOF'
# Proxmox VE No-Subscription Repository
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# Clean and update
rm -rf /var/lib/apt/lists/*
mkdir -p /var/lib/apt/lists/partial
apt clean
apt update
```


