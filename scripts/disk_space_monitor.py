#!/usr/bin/env python3
"""
Linux Disk Space Monitor
Checks main directories and alerts if disk usage exceeds 90%

Author: Tammy DiPrima

# Run with default 90% threshold
python3 disk_space_monitor.py

# Run with custom threshold (85%)
python3 disk_space_monitor.py 85

# Run with sudo for full system access
sudo python3 disk_space_monitor.py
"""

import os
import shutil
import sys
from pathlib import Path


def get_disk_usage(path):
    """Get disk usage statistics for a given path"""
    try:
        total, used, free = shutil.disk_usage(path)
        usage_percent = (used / total) * 100
        return {
            "path": path,
            "total": total,
            "used": used,
            "free": free,
            "usage_percent": usage_percent,
        }
    except (OSError, PermissionError) as e:
        return {"path": path, "error": str(e), "usage_percent": 0}


def format_bytes(bytes_value):
    """Convert bytes to human readable format"""
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if bytes_value < 1024.0:
            return f"{bytes_value:.1f}{unit}"
        bytes_value /= 1024.0
    return f"{bytes_value:.1f}PB"


def check_disk_space(threshold=90):
    """
    Check disk space usage for main Linux directories
    Returns True if all are below threshold, False otherwise
    """
    # Main directories to check
    directories_to_check = [
        "/",  # Root filesystem
        "/home",  # User home directories
        "/var",  # Variable data (logs, databases, etc.)
        "/tmp",  # Temporary files
        "/usr",  # User programs and data
        "/opt",  # Optional software packages
        "/boot",  # Boot files
    ]

    # Additional mounted filesystems
    try:
        mounts_file = Path("/proc/mounts")
        mounts = mounts_file.read_text().splitlines()

        for line in mounts:
            parts = line.strip().split()
            if len(parts) >= 2:
                mount_point = parts[1]
                # Add common mount points that aren't in our default list
                if mount_point.startswith("/mnt/") or mount_point.startswith("/media/"):
                    directories_to_check.append(mount_point)
    except (OSError, PermissionError):
        pass  # Continue with default directories if we can't read /proc/mounts

    # Remove duplicates and non-existent paths
    directories_to_check = list(set(directories_to_check))
    directories_to_check = [d for d in directories_to_check if Path(d).exists()]

    all_ok = True
    results = []

    print(f"Disk Space Monitor - Checking for usage above {threshold}%")
    print("=" * 60)

    for directory in sorted(directories_to_check):
        usage_info = get_disk_usage(directory)
        results.append(usage_info)

        if "error" in usage_info:
            print(f"❌ {directory}: Error - {usage_info['error']}")
            continue

        usage_percent = usage_info["usage_percent"]
        status = "❌ CRITICAL" if usage_percent > threshold else "✅ OK"

        if usage_percent > threshold:
            all_ok = False

        print(
            f"{status} {directory}: {usage_percent:.1f}% "
            f"({format_bytes(usage_info['used'])}/{format_bytes(usage_info['total'])})"
        )

    print("=" * 60)

    if not all_ok:
        print("⚠️  WARNING: One or more filesystems exceed the threshold!")
        print("\nRecommendations:")
        print("- Clean temporary files: sudo rm -rf /tmp/* /var/tmp/*")
        print("- Clean package cache: sudo apt clean (or equivalent for your distro)")
        print("- Check log files: sudo find /var/log -name '*.log' -size +100M")
        print("- Analyze disk usage: du -h --max-depth=1 / | sort -hr")
        return False
    else:
        print("✅ All filesystems are below the threshold. System is healthy!")
        return True


def main():
    """Main function with command line argument support"""
    threshold = 90

    # Simple command line argument parsing
    if len(sys.argv) > 1:
        try:
            threshold = float(sys.argv[1])
            if threshold < 0 or threshold > 100:
                print("Error: Threshold must be between 0 and 100")
                sys.exit(1)
        except ValueError:
            print("Error: Threshold must be a number")
            print("Usage: python3 disk_monitor.py [threshold_percentage]")
            print("Example: python3 disk_monitor.py 85")
            sys.exit(1)

    # Check if running as root for better access to system directories
    if os.geteuid() != 0:
        print(
            "Note: Running without root privileges. Some directories may be inaccessible."
        )
        print()

    success = check_disk_space(threshold)

    # Exit with appropriate code for scripting
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
