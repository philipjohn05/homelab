## Overview


Cloud-init automates the initial configuration of VMs cloned from the template. This document explains the cloud-init setup and customization options.


## Important Security Notes

**Before using this configuration:**

1. Replace placeholder SSH keys with your actual public key
2. Never commit private keys to git repositories
3. Generate your SSH key pair:
```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
```


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

```yaml
#cloud-config
users:
  - name: admin
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... admin-key

  - name: developer
    groups: wheel,docker
    sudo: ALL=(ALL) ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... dev-key

ssh_pwauth: false
```

### Custom SSH Configuration


```yaml
#cloud-config
users:
  - name: rocky
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... key1
      - ssh-ed25519 AAAAC3... key2

write_files:
  - path: /etc/ssh/sshd_config.d/50-custom.conf
    permissions: '0644'
    owner: root:root
    content: |
      PasswordAuthentication no
      PubkeyAuthentication yes
      PermitRootLogin no
      ClientAliveInterval 300
      ClientAliveCountMax 2

runcmd:
  - systemctl restart sshd
```

### Running Commands on First Boot

```yaml

#cloud-config
users:
  - name: rocky
    # ... user config ...

runcmd:
  - hostnamectl set-hostname custom-hostname
  - systemctl restart sshd
  - dnf install -y vim git
  - echo "Setup complete" > /tmp/cloud-init-complete

```

### Setting Hostname

```yaml
#cloud-config
hostname: k8s-master-01
fqdn: k8s-master-01.local

users:
  - name: rocky
    # ... user config ...
```

### Creating Files

```yaml
#cloud-config
write_files:
  - path: /etc/motd
    permissions: '0644'
    owner: root:root
    content: |
      Welcome to Kubernetes Node
      This system is managed by cloud-init

  - path: /usr/local/bin/custom-script.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/bin/bash
      echo "Custom script executed"

users:
  - name: rocky
    # ... user config ...
```

### Role-Specific Configurations

Kubernetes Master Nodes
File: /var/lib/vz/snippets/k8s-master-user.yaml

```yaml
#cloud-config
users:
  - name: k8sadmin
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... your-key

hostname: k8s-master

runcmd:
  - echo "Kubernetes Master Node" > /etc/motd
```

Kubernetes Worker Nodes
File: /var/lib/vz/snippets/k8s-worker-user.yaml

```yaml

#cloud-config
users:
  - name: k8sadmin
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... your-key

hostname: k8s-worker

runcmd:
  - echo "Kubernetes Worker Node" > /etc/motd
```

### Applying Cloud-Init Config to VMs
### Via Command Line
```bash
# Apply default config
qm set 300 --cicustom "user=local:snippets/user-config.yaml"

# Apply master config
qm set 301 --cicustom "user=local:snippets/k8s-master-user.yaml"

# Apply worker config
qm set 401 --cicustom "user=local:snippets/k8s-worker-user.yaml"

# Regenerate cloud-init image
qm cloudinit update 300
```

### Verification
```bash
# SSH to VM
ssh rocky@<VM-IP>

# Check cloud-init status
cloud-init status

# View cloud-init output
sudo cat /var/log/cloud-init-output.log

# View cloud-init logs
sudo cat /var/log/cloud-init.log

# Check what user-data was applied
sudo cat /var/lib/cloud/instance/user-data.txt
```

### Debugging Cloud-Init
```bash
# Re-run cloud-init (for testing)
sudo cloud-init clean
sudo cloud-init init
sudo cloud-init modules --mode=config
sudo cloud-init modules --mode=final

# Check for errors
sudo journalctl -u cloud-init

# Validate cloud-init config
cloud-init schema --config-file /var/lib/vz/snippets/user-config.yaml
```

---

**These documentation files cover:**

1. Complete template creation process
2. All configuration steps
3. Cloud-init setup and usage
4. Troubleshooting guide
5. Verification procedures

**Ready to move to Terraform setup?**


