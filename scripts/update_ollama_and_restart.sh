#!/bin/bash
# Description: Script to update ollama, add environment to service, and restart.
# Author: tdiprima

# Update Ollama
echo "Updating Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
ollama --version

# Restart ollama.service
echo "Resetting ollama.service..."

# Add back Environment="OLLAMA_HOST=0.0.0.0:11434"
# sudo sed -i 's/^Environment=/Environment="OLLAMA_HOST=0.0.0.0:11434"/' /etc/systemd/system/ollama.service
# Add a new Environment line underneath the existing one
sudo sed -i '/Environment=/a\Environment="OLLAMA_HOST=0.0.0.0:11434"' /etc/systemd/system/ollama.service

# Reload the systemd daemon to pick up changes
echo "Reloading systemd configuration..."
sudo systemctl daemon-reload

# Restart the Ollama service
echo "Restarting ollama.service..."
sudo systemctl restart ollama.service

# Check the status of the service to ensure it's running properly
echo "Checking the status of ollama.service..."
sudo systemctl status ollama.service
