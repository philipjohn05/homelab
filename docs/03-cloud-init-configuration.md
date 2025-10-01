## Overview

Cloud-init automates the initial configuration of VMs cloned from the template. This document explains the cloud-init setup and customization options.

## Cloud-Init User Configuration

Location: `/var/lib/vz/snippets/user-config.yaml`

### Basic Configuration
```yaml
#cloud-config
users:
  - name: rocky
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... your-key-here

ssh_pwauth: false
disable_root: true
```

### Configuration Options
Users Block:

name: Username to create
groups: Additional groups (wheel for sudo)
sudo: Sudo permissions
shell: Default shell
ssh_authorized_keys: List of SSH public keys

SSH Settings:

ssh_pwauth: Enable/disable password authentication
disable_root: Disable root login

### Multiple User Configuration
