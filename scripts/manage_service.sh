#!/bin/bash

# Systemd Service Management - Check, troubleshoot, and manage a service

# Check the current status of the service
echo "=== Service Status ==="
systemctl status myapp

# View recent logs for troubleshooting
echo -e "\n=== Recent Logs (last 10 minutes) ==="
journalctl -u myapp --since "10 minutes ago"

# Restart the service to apply changes or recover from issues
echo -e "\n=== Restarting Service ==="
systemctl restart myapp

# Enable service to start automatically on boot
echo -e "\n=== Enabling Service on Boot ==="
systemctl enable myapp
