#!/bin/bash
# Description: Script to update ollama, add environment, restart, and check.
# Author: tdiprima

# Update Ollama
echo "Updating Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
ollama --version

# Restart ollama.service
echo "Resetting ollama.service..."

# Ensure Environment line exists or append it
if ! grep -q 'Environment="OLLAMA_HOST=0.0.0.0:11434"' /etc/systemd/system/ollama.service; then
    sudo sed -i '/Environment=/a\Environment="OLLAMA_HOST=0.0.0.0:11434"' /etc/systemd/system/ollama.service
fi

# Reload the systemd daemon to pick up changes
echo "Reloading systemd configuration..."
sudo systemctl daemon-reload

# Restart the Ollama service
echo "Restarting ollama.service..."
sudo systemctl restart ollama.service

# Wait and check status
echo "Waiting for Ollama service to stabilize..."
sleep 5
echo "Checking the status of ollama.service..."
sudo systemctl status ollama.service --no-pager

# Test connection
echo "Testing Ollama connection..."
curl -s http://0.0.0.0:11434 || echo "Failed to connect to Ollama"
