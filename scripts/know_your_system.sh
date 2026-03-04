#!/bin/bash

# Know Your System - Quick system status overview

# Who you're logged in as (vital for permissions)
echo "=== Current User ==="
whoami

# What machine you're on
echo -e "\n=== Hostname ==="
hostname

# What the disk space looks like
echo -e "\n=== Disk Usage ==="
df -h

# What memory looks like
echo -e "\n=== Memory Usage ==="
free -m

# System load and uptime (whether the system is under stress)
echo -e "\n=== System Load & Uptime ==="
uptime
