#!/usr/bin/env python3
"""
Script to set up passwordless SSH authentication to multiple servers.
This will copy your SSH public key to the authorized_keys file on each server.
"""

import getpass
import os
import sys
from pathlib import Path
from typing import Tuple
import subprocess

import paramiko


def generate_ssh_key_if_needed(key_path: str = "~/.ssh/id_rsa") -> Tuple[str, str]:
    """
    Check if SSH key exists, generate if it doesn't.
    Returns paths to private and public keys.
    """
    private_key = os.path.expanduser(key_path)
    public_key = f"{private_key}.pub"

    if not Path(private_key).exists():
        print(f"SSH key not found at {private_key}")
        response = input("Would you like to generate a new SSH key? (y/n): ").lower()
        if response == "y":
            Path(private_key).parent.mkdir(parents=True, exist_ok=True)
            # Using os.system() with an f-string is dangerous. Bad guys could sneak in malicious commands.
            # os.system(f'ssh-keygen -t rsa -b 4096 -f {private_key} -N ""')
            subprocess.run(["ssh-keygen", "-t", "rsa", "-b", "4096", "-f", private_key, "-N", ""], check=True)
            print(f"SSH key generated at {private_key}")
        else:
            print("Please generate an SSH key manually or specify an existing one.")
            sys.exit(1)

    return private_key, public_key


def read_public_key(public_key_path: str) -> str:
    """Read the SSH public key from file."""
    public_key_path = os.path.expanduser(public_key_path)
    try:
        with open(public_key_path, "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        print(f"Public key not found at {public_key_path}")
        sys.exit(1)


def setup_passwordless_auth(
    host: str, username: str, password: str, public_key: str, port: int = 22
) -> bool:
    """
    Copy SSH public key to remote server's authorized_keys file.
    Returns True if successful, False otherwise.
    """
    ssh = paramiko.SSHClient()
    # AutoAddPolicy() blindly trusts any server. This is how man-in-the-middle attacks happen.
    # ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.load_system_host_keys()  # Uses ~/.ssh/known_hosts

    try:
        # Connect to the server
        print(f"Connecting to {host}...")
        ssh.connect(host, port=port, username=username, password=password, timeout=10)

        # Create .ssh directory if it doesn't exist
        stdin, stdout, stderr = ssh.exec_command("mkdir -p ~/.ssh && chmod 700 ~/.ssh")  # nosec B601
        stdout.read()

        # Check if key already exists in authorized_keys
        stdin, stdout, stderr = ssh.exec_command('cat ~/.ssh/authorized_keys 2>/dev/null || echo ""')  # nosec B601
        existing_keys = stdout.read().decode("utf-8")

        if public_key in existing_keys:
            print(f"  ✓ Public key already exists in authorized_keys on {host}")
        else:
            # Append public key to authorized_keys
            escaped_key = public_key.replace('"', '\\"')
            command = f'echo "{escaped_key}" >> ~/.ssh/authorized_keys'
            stdin, stdout, stderr = ssh.exec_command(command)  # nosec B601
            stdout.read()

            # Set proper permissions
            stdin, stdout, stderr = ssh.exec_command("chmod 600 ~/.ssh/authorized_keys")  # nosec B601
            stdout.read()

            print(f"  ✓ Public key added to {host}")

        # Test passwordless connection
        test_ssh = paramiko.SSHClient()
        test_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        private_key_path = os.path.expanduser("~/.ssh/id_rsa")

        try:
            key = paramiko.RSAKey.from_private_key_file(private_key_path)
            test_ssh.connect(host, port=port, username=username, pkey=key, timeout=5)
            test_ssh.close()
            print(f"  ✓ Passwordless authentication verified for {host}")
        except Exception as e:
            print(
                f"  ⚠ Warning: Could not verify passwordless auth for {host}: {e}"
            )

        ssh.close()
        return True

    except paramiko.AuthenticationException:
        print(
            f"  ✗ Authentication failed for {host}. Please check username and password."
        )
        return False
    except paramiko.SSHException as e:
        print(f"  ✗ SSH connection error for {host}: {e}")
        return False
    except Exception as e:
        print(f"  ✗ Error connecting to {host}: {e}")
        return False
    finally:
        ssh.close()


def main():
    print("=" * 60)
    print("SSH Passwordless Authentication Setup")
    print("=" * 60)

    # Server configuration
    # You can modify this list with your actual server IPs
    servers = [
        # "192.168.1.10",
        # "192.168.1.11",
        # "192.168.1.12",
        # "192.168.1.13",
        # "192.168.1.14",
    ]

    # Check if servers are defined
    if not servers:
        print(
            "\nPlease edit the script and add your server IP addresses to the 'servers' list."
        )
        print("Example: servers = ['192.168.1.10', '192.168.1.11', ...]")

        # Allow manual input
        manual = input("\nOr enter server IPs now (comma-separated): ").strip()
        if manual:
            servers = [ip.strip() for ip in manual.split(",")]
        else:
            sys.exit(1)

    print(f"\nServers to configure: {', '.join(servers)}")

    # Get SSH key paths
    private_key, public_key = generate_ssh_key_if_needed()

    # Read public key
    public_key_content = read_public_key(public_key)
    print(f"\nUsing public key from: {public_key}")

    # Get credentials
    print("\nEnter credentials for the servers:")
    username = input("Username (same for all servers): ").strip()

    # Option to use same password for all servers
    same_password = input("Use same password for all servers? (y/n): ").lower() == "y"

    if same_password:
        password = getpass.getpass("Password: ")
        passwords = {server: password for server in servers}
    else:
        passwords = {}
        for server in servers:
            passwords[server] = getpass.getpass(f"Password for {server}: ")

    # Custom SSH port if needed
    port_input = input("SSH port (default 22): ").strip()
    port = int(port_input) if port_input else 22

    # Setup passwordless auth for each server
    print("\nSetting up passwordless authentication...")
    print("-" * 40)

    successful = []
    failed = []

    for server in servers:
        password = passwords[server]
        if setup_passwordless_auth(
            server, username, password, public_key_content, port
        ):
            successful.append(server)
        else:
            failed.append(server)
        print()

    # Summary
    print("=" * 60)
    print("Setup Complete!")
    print("-" * 40)

    if successful:
        print(f"✓ Successfully configured ({len(successful)}):")
        for server in successful:
            print(f"  - {server}")

    if failed:
        print(f"\n✗ Failed ({len(failed)}):")
        for server in failed:
            print(f"  - {server}")

    print("\n" + "=" * 60)

    if successful:
        print("\nYou can now SSH to the configured servers without a password:")
        print(f"  ssh {username}@<server_ip>")
        if port != 22:
            print(f"  (Using port {port})")


if __name__ == "__main__":
    main()
