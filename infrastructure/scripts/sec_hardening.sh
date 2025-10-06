#!/bin/bash
# Rocky Linux Security Hardening Script

echo "Starting security hardening..."

# 1. Update all packages
echo "=== Updating packages ==="
dnf update -y

# 2. Configure automatic security updates
echo "=== Configuring automatic updates ==="
dnf install -y dnf-automatic
systemctl enable --now dnf-automatic.timer

cat > /etc/dnf/automatic.conf <<'EOF'
[commands]
upgrade_type = security
download_updates = yes
apply_updates = yes
EOF

# 3. Configure SSH security
echo "=== Hardening SSH ==="
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# For template, temporarily allow password (will be disabled after cloud-init)
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 4. Configure firewall
echo "=== Configuring firewall ==="
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# 5. SELinux configuration (keep enforcing)
echo "=== Configuring SELinux ==="
setenforce 1
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Enable container management
setsebool -P container_manage_cgroup on
setsebool -P virt_sandbox_use_all_caps on

# 6. Kernel hardening
echo "=== Hardening kernel parameters ==="
cat > /etc/sysctl.d/99-kubernetes.conf <<'EOF'
# Kubernetes networking
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1

# Security hardening
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
fs.suid_dumpable = 0
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
EOF

# Apply sysctl settings
sysctl --system

# 7. Load required kernel modules
cat > /etc/modules-load.d/kubernetes.conf <<'EOF'
overlay
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

# Load modules now
modprobe overlay
modprobe br_netfilter
modprobe ip_vs
modprobe ip_vs_rr

# 8. Disable swap
echo "=== Disabling swap ==="
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 9. Configure chronyd (time sync)
echo "=== Configuring time synchronization ==="
dnf install -y chrony
systemctl enable --now chronyd

cat > /etc/chrony.conf <<'EOF'
pool 0.rocky.pool.ntp.org iburst
pool 1.rocky.pool.ntp.org iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF

systemctl restart chronyd

# 10. Audit logging
echo "=== Configuring audit logging ==="
dnf install -y audit
systemctl enable --now auditd

# 11. Remove unnecessary packages
echo "=== Removing unnecessary packages ==="
dnf remove -y \
    iwl* \
    *-firmware 2>/dev/null || true

# 12. Set up minimal bashrc
cat > /root/.bashrc <<'EOF'
# .bashrc
alias ll='ls -lah'
alias k='kubectl'
export EDITOR=vi
export PATH=$PATH:/usr/local/bin
EOF

echo "Security hardening complete!"
