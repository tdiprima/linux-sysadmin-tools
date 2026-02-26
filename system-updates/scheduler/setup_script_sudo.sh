#!/bin/bash
# Script to set up passwordless sudo for ONLY your specific update scripts
# This is much more secure than allowing all package manager commands

echo "Setting up passwordless sudo for your specific update scripts..."

# Get the full path to your scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_UBUNTU="$SCRIPT_DIR/update_ubuntu"
UPDATE_RHEL="$SCRIPT_DIR/update_rhel" 
UPDATE_ROCKY="$SCRIPT_DIR/update_rocky"

# Make sure scripts are executable and owned by you
chmod +x "$UPDATE_UBUNTU" "$UPDATE_RHEL" "$UPDATE_ROCKY" 2>/dev/null

# Backup current sudoers file
sudo cp /etc/sudoers /etc/sudoers.backup.$(date +%Y%m%d_%H%M%S)

# Create a very specific sudoers file for ONLY your scripts
cat << EOF | sudo tee /etc/sudoers.d/99-update-scripts
# Allow passwordless sudo for ONLY these specific update scripts
# User: $USER
$USER ALL=(ALL) NOPASSWD: $UPDATE_UBUNTU
$USER ALL=(ALL) NOPASSWD: $UPDATE_RHEL
$USER ALL=(ALL) NOPASSWD: $UPDATE_ROCKY
EOF

# Set proper permissions
sudo chmod 440 /etc/sudoers.d/99-update-scripts

echo "Passwordless sudo configured for your specific scripts:"
echo "  - $UPDATE_UBUNTU"
echo "  - $UPDATE_RHEL" 
echo "  - $UPDATE_ROCKY"
echo ""
echo "Now modify your scripts to call themselves with sudo..."