#!/bin/bash

# Fast Disk Space Analysis Script for /data01
# Optimized for speed - parallel execution and minimal traversal

echo "================================================================"
echo "                 FAST DISK SPACE ANALYSIS REPORT"
echo "                 $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================"
echo

# Get current disk usage
echo "CURRENT DISK USAGE:"
echo "-------------------"
df -h /data01
echo

# First, just get the top-level directories WITHOUT recursion (MUCH faster)
echo "TOP-LEVEL DIRECTORY SIZES (depth=1 only):"
echo "-----------------------------------------"
echo "Calculating sizes of immediate subdirectories only..."
echo
# Use du with max-depth=1 and sort by numeric value for speed
du -h --max-depth=1 /data01 2>/dev/null | sort -hr | head -20 &
pid1=$!

# Run other commands in parallel while du is working
echo
echo "SCANNING FOR LARGE FILES AND LOGS IN PARALLEL..."
echo "================================================"

# Find large files in background
(
    echo
    echo "LARGE FILES (>1GB):"
    echo "-------------------"
    find /data01 -type f -size +1G -printf "%s %p\n" 2>/dev/null | sort -nr | head -20 | while read size path; do
        ls -lh "$path" 2>/dev/null
    done
) &
pid2=$!

# Find old logs in background
(
    echo
    echo "OLD LOG FILES (>30 days) - First 20:"
    echo "------------------------------------"
    find /data01 -name "*.log" -mtime +30 -type f -printf "%s %p\n" 2>/dev/null | sort -nr | head -20 | while read size path; do
        ls -lh "$path" 2>/dev/null
    done
) &
pid3=$!

# Find core dumps in background
(
    echo
    echo "CORE DUMP FILES:"
    echo "----------------"
    find /data01 \( -name "core.*" -o -name "*.core" \) -type f -ls 2>/dev/null | head -10
) &
pid4=$!

# Wait for all background jobs
wait $pid1 $pid2 $pid3 $pid4

echo
echo "================================================================"
echo "QUICK RECOMMENDATIONS:"
echo "================================================================"
echo "1. Check the largest directories shown above"
echo "2. Remove/compress old logs: find /data01 -name '*.log' -mtime +30 -exec gzip {} \;"
echo "3. Remove core dumps: find /data01 \( -name 'core.*' -o -name '*.core' \) -delete"
echo "4. Archive large files that aren't actively used"
echo
echo "For a deeper analysis of a specific directory, run:"
echo "   du -h --max-depth=1 /data01/DIRNAME | sort -hr"
echo "================================================================"