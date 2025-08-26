#!/bin/bash

# Disk Space Analysis Script for /data01
# This script analyzes disk usage and identifies potential space-saving opportunities

echo "================================================================"
echo "                 DISK SPACE ANALYSIS REPORT"
echo "                 $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================"
echo

# Get current disk usage
echo "CURRENT DISK USAGE:"
echo "-------------------"
df -h /data01
echo

# Top 20 largest directories
echo "TOP 20 LARGEST DIRECTORIES IN /data01:"
echo "--------------------------------------"
echo "These are the directories consuming the most space:"
echo
du -h --max-depth=1 /data01 2>/dev/null | sort -hr | head -20
echo

# Large files (>1GB)
echo "LARGE FILES (>1GB):"
echo "-------------------"
echo "Individual files larger than 1GB that could be archived or removed:"
echo
large_files=$(find /data01 -type f -size +1G -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr)
if [ -z "$large_files" ]; then
    echo "No files larger than 1GB found."
else
    echo "$large_files"
fi
echo

# Old log files (>30 days)
echo "OLD LOG FILES (>30 days):"
echo "-------------------------"
echo "Log files that haven't been modified in 30+ days (candidates for deletion/compression):"
echo
old_logs=$(find /data01 -name "*.log" -mtime +30 -exec ls -lh {} \; 2>/dev/null)
if [ -z "$old_logs" ]; then
    echo "No log files older than 30 days found."
else
    echo "$old_logs"
    # Count and calculate potential space savings
    log_count=$(echo "$old_logs" | wc -l)
    log_size=$(find /data01 -name "*.log" -mtime +30 -exec du -ch {} + 2>/dev/null | grep total$ | awk '{print $1}')
    echo
    echo "Total: $log_count old log files using approximately $log_size"
fi
echo

# Core dump files
echo "CORE DUMP FILES:"
echo "----------------"
echo "Core dumps that can typically be safely removed:"
echo
core_files=$(find /data01 \( -name "core.*" -o -name "*.core" \) 2>/dev/null)
if [ -z "$core_files" ]; then
    echo "No core dump files found."
else
    ls -lh $core_files 2>/dev/null
    # Calculate total size
    core_size=$(find /data01 \( -name "core.*" -o -name "*.core" \) -exec du -ch {} + 2>/dev/null | grep total$ | awk '{print $1}')
    echo
    echo "Total core dump space: $core_size"
fi
echo

# Summary and recommendations
echo "================================================================"
echo "RECOMMENDATIONS:"
echo "================================================================"
echo "1. Review the largest directories and consider:"
echo "   - Moving old data to archive storage"
echo "   - Deleting unnecessary files"
echo "   - Compressing infrequently accessed data"
echo
echo "2. For old log files:"
echo "   - Compress with: find /data01 -name '*.log' -mtime +30 -exec gzip {} \;"
echo "   - Or delete with: find /data01 -name '*.log' -mtime +30 -delete"
echo
echo "3. Remove core dumps (after investigating if needed):"
echo "   - find /data01 \( -name 'core.*' -o -name '*.core' \) -delete"
echo
echo "4. Consider implementing:"
echo "   - Automated log rotation (logrotate)"
echo "   - Regular cleanup cron jobs"
echo "   - Disk usage monitoring alerts"
echo "================================================================"
