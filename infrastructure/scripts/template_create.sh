#!/bin/bash
# Clean VM for Template Creation

echo "Cleaning VM for template conversion..."

# 1. Clean cloud-init
echo "=== Cleaning cloud-init ==="
cloud-init clean --logs --seed

# 2. Remove SSH host keys (will be regenerated)
echo "=== Removing SSH host keys ==="
rm -f /etc/ssh/ssh_host_*

# 3. Remove machine-id
echo "=== Removing machine-id ==="
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# 4. Clean network configurations
echo "=== Cleaning network configs ==="
rm -f /etc/udev/rules.d/70-persistent-net.rules

# Clean NetworkManager connections
rm -f /etc/NetworkManager/system-connections/*

# 5. Clean logs
echo "=== Cleaning logs ==="
logrotate -f /etc/logrotate.conf
rm -f /var/log/*-????????
rm -f /var/log/*.gz
rm -f /var/log/dmesg.old
rm -rf /var/log/anaconda
cat /dev/null > /var/log/audit/audit.log
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/lastlog
cat /dev/null > /var/log/grubby

# 6. Clean temporary files
echo "=== Cleaning temporary files ==="
rm -rf /tmp/*
rm -rf /var/tmp/*

# 7. Clean bash history
echo "=== Cleaning bash history ==="
history -c
cat /dev/null > ~/.bash_history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/*/.bash_history

# 8. Clean package cache
echo "=== Cleaning package cache ==="
dnf clean all
rm -rf /var/cache/dnf/*
rm -rf /var/cache/yum/*

# 9. Clean cloud-init instance data
echo "=== Final cloud-init clean ==="
rm -rf /var/lib/cloud/instances/*
rm -rf /var/lib/cloud/instance
rm -rf /var/lib/cloud/data
rm -rf /var/lib/cloud/sem

# 10. Truncate audit logs
echo "=== Truncating audit logs ==="
cat /dev/null > /var/log/audit/audit.log
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/lastlog

echo ""
echo "VM cleaned and ready for template conversion!"
echo ""
echo "Next steps:"
echo "1. Shutdown this VM: shutdown -h now"
echo "2. In Proxmox: Right-click VM → Convert to Template"
