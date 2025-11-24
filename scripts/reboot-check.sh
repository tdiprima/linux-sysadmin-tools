#!/bin/bash

# Check if any upgradable packages come from the security repo
if apt list --upgradable 2>/dev/null | grep -qi security; then
    echo "🔥 Security updates detected — consider a prompt reboot."
else
    echo "🟢 No security updates. Reboot when convenient."
fi

# Optional: also check if a reboot is even required
if [ -f /var/run/reboot-required ]; then
    echo "⚠️ System says a reboot is required."
else
    echo "✨ No reboot required."
fi

# apt list --upgradable | grep -i security
# ubuntu-security-status
