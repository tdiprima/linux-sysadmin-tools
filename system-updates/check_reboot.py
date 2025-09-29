# We've updated the system, now check to see if we need to reboot
# Enhanced version with error handling and timeout control
import socket

import paramiko
from paramiko.ssh_exception import (AuthenticationException,
                                    NoValidConnectionsError, SSHException)

servers = [
    # "192.168.1.10",
    # "192.168.1.11",
    # "192.168.1.12",
    # "192.168.1.13",
    # "192.168.1.14",
]

username = "USERNAME"
timeout = 10  # Connection timeout in seconds


def check_ubuntu_reboot(ssh):
    """Check if Ubuntu/Debian server needs reboot"""
    stdin, stdout, stderr = ssh.exec_command(
        'test -f /var/run/reboot-required && echo "Yes, reboot needed" || echo "All good"'
    )
    return stdout.read().decode().strip()


def check_rhel_reboot(ssh):
    """Check if RHEL/CentOS server needs reboot"""
    stdin, stdout, stderr = ssh.exec_command("needs-restarting -r")
    return stdout.read().decode().strip()


def connect_and_check(server, username, check_function, timeout=10):
    """Connect to server and run reboot check with error handling"""
    try:
        print(f"Connecting to {server}...")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        # Connect with timeout
        ssh.connect(server, username=username, timeout=timeout)

        # Run the check
        result = check_function(ssh)
        print(f"{server}:\n{result}\n")

        ssh.close()
        return True

    except AuthenticationException as e:
        print(f"{server}: Authentication failed - {e}\n")
        return False
    except NoValidConnectionsError as e:
        print(f"{server}: Connection failed - {e}\n")
        return False
    except socket.timeout as e:
        print(f"{server}: Connection timeout - {e}\n")
        return False
    except SSHException as e:
        print(f"{server}: SSH error - {e}\n")
        return False
    except Exception as e:
        print(f"{server}: Unexpected error - {e}\n")
        return False


# Check Ubuntu/Debian servers
print("=== Checking Ubuntu/Debian Servers ===")
for server in servers:
    connect_and_check(server, username, check_ubuntu_reboot, timeout)

# Check RHEL server
print("=== Checking RHEL Server ===")
rhel_server = "172.28.223.208"
connect_and_check(rhel_server, username, check_rhel_reboot, timeout)

print("Reboot check completed.")
