## setup\_passwordless\_sudo.sh

```bash
#!/bin/bash
# Script to set up passwordless sudo for a specific Python script
# Run this once on each Linux system where you want automated updates

echo "Setting up passwordless sudo for the update scheduler script..."

# Backup current sudoers file
sudo cp /etc/sudoers /etc/sudoers.backup.$(date +%Y%m%d_%H%M%S)

# Create a new sudoers rule just for your update scheduler Python script
# Replace /path/to/venv/bin/python and /path/to/update_scheduler.py with your actual paths
cat << EOF | sudo tee /etc/sudoers.d/99-update-scheduler
# Allow passwordless sudo only for the update scheduler script
$USER ALL=(ALL) NOPASSWD: /path/to/venv/bin/python /path/to/update_scheduler.py
EOF

# Set proper permissions
sudo chmod 440 /etc/sudoers.d/99-update-scheduler

echo "Passwordless sudo configured for the update scheduler script."
echo "You can now run the scheduler without entering a password."
```

### Note:
Originally, this script allowed passwordless sudo for all package managers (apt, yum, dnf, etc.).

We’ve tightened it so it **only works for the Python scheduler script** — even more secure.

---

## How update\_scheduler.py Works with the Sudo Setup

The `update_scheduler.py` script calls the update scripts (like `update_ubuntu`) via:

```python
sh.Command(f"./{script_name}")()
```

*(Line 17)*

These update scripts contain commands such as `apt update`, `dnf update`, etc., which require root privileges.

---

### **Without setup\_passwordless_sudo.sh**

* You run the scheduler as root (via `sudo`)
* But when it calls `./update_ubuntu`, that script will still **prompt for a password** when it hits `sudo` commands inside it

---

### **With setup\_passwordless_sudo.sh**

* The scheduler runs as root without a password prompt
* The update scripts it calls can run their internal `sudo` commands **passwordlessly**
* The whole process can run **unattended**

---

### **Flow**

1. **Run the scheduler as root**

   ```bash
   sudo /path/to/venv/bin/python /path/to/update_scheduler.py
   ```

2. Scheduler calls:

   ```bash
   ./update_ubuntu
   ```

3. `update_ubuntu` runs commands like:

   ```bash
   sudo apt update
   sudo apt upgrade
   ```

   — which succeed **passwordlessly**, thanks to the targeted sudoers config.

---

## brew\_scheduler.py

```
Error: Running Homebrew as root is extremely dangerous and no longer supported.
As Homebrew does not drop privileges on installation you would be giving all
build scripts full access to your system.
```

You're facing a common issue with automated Homebrew updates. The script correctly refuses to run as root (which is dangerous), but some packages require elevated privileges for certain operations.

### Solution: Configure sudo for passwordless Homebrew operations (Recommended)

Edit your sudoers file to allow specific Homebrew commands without a password:

```bash
sudo visudo
```

Add these lines (replace `YOUR_USERNAME` with your actual username):

```sh
# Allow passwordless sudo for Homebrew operations
YOUR_USERNAME ALL=(ALL) NOPASSWD: /usr/local/bin/brew *
```

**Important**: This grants passwordless sudo only for brew commands, which is more secure than blanket sudo access.

<br>
