#!/bin/bash
# Purpose: Runs a Python script in the background using nohup and monitors the nohup.out log file,
#          truncating it when it exceeds a specified size to prevent it from growing too large.
# Usage: Save this script as manage_nohup.sh, make it executable with 'chmod +x manage_nohup.sh',
#        then run with 'nohup ./manage_nohup.sh &'. Ensure 'your_command'
#        is in the same directory. Adjust MAXSIZE (in bytes) to change the log size limit.
LOGFILE="nohup.out"
MAXSIZE=$((100 * 1024 * 1024))  # 100MB in bytes

# Run your command with nohup
nohup your_command &

# Monitor log size in the background
while true; do
    if [ -f "$LOGFILE" ]; then
        SIZE=$(stat -f %z "$LOGFILE" 2>/dev/null || stat -c %s "$LOGFILE" 2>/dev/null)
        if [ "$SIZE" -gt "$MAXSIZE" ]; then
            > "$LOGFILE"  # Truncate to zero
        fi
    fi
    sleep 60  # Check every minute
done
