#!/bin/bash
# Description: Generate example log file
# Author: tdiprima

# Log file name
LOG_FILE="example-logs.log"

# Create the log file with example error entries
echo "Generating example log file: $LOG_FILE"
cat <<EOL > "$LOG_FILE"
Sample log entry: [2024-12-27] ERROR: Something went wrong
Sample log entry: [2024-12-27] INFO: System running smoothly
Sample log entry: [2024-12-27] WARNING: Disk space low
Sample log entry: [2024-12-27] ERROR: Failed to connect to database
Sample log entry: [2024-12-27] DEBUG: Debugging network issue
EOL

echo "Log file created: $LOG_FILE"
