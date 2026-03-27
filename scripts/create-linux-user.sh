#!/bin/bash
# This script creates a new Linux user with home dir, password, and sudo access.

USERNAME="newuser"
echo "Creating user: $USERNAME"

# Create user with home directory
sudo useradd -m "$USERNAME"

# Set password (change after first login)
echo "$USERNAME:password123" | sudo chpasswd

# Add user to sudo group
sudo usermod -aG sudo "$USERNAME"

echo "User $USERNAME created and configured successfully ✅"
