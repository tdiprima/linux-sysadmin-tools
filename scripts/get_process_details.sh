#!/bin/bash

# ======================================================
# Script: get_process_details.sh
# Description:
#   Given a PID, this script:
#     - Verifies the process is running
#     - Prints:
#         • Start time
#         • Elapsed time (duration running)
#         • User
#         • Command-line arguments
#     - Logs this info to a timestamped log file
#
# Usage:
#   ./get_process_details.sh <PID>
# ======================================================

PID="$1"
LOGDIR="/var/log"
LOGFILE="process_${PID}_$(date +%Y%m%d_%H%M%S).log"

# Fallback if /var/log isn't writable
if [[ ! -w "$LOGDIR" ]]; then
  LOGDIR="."
fi

LOGPATH="$LOGDIR/$LOGFILE"

# Check if PID was provided
if [[ -z "$PID" ]]; then
  echo "❌ Error: No PID provided."
  echo "Usage: $0 <PID>"
  exit 1
fi

# Check if process is running
if ! ps -p "$PID" > /dev/null 2>&1; then
  echo "❌ Process with PID $PID is not running."
  exit 1
fi

# Gather process info
START_TIME=$(ps -p "$PID" -o lstart=)
ELAPSED_TIME=$(ps -p "$PID" -o etime=)
USER=$(ps -p "$PID" -o user=)
CMD=$(ps -p "$PID" -o args=)

# Print to terminal
echo "✅ Process $PID Details:"
echo "  🕒 Start Time  : $START_TIME"
echo "  ⏱️  Elapsed Time : $ELAPSED_TIME"
echo "  👤 User        : $USER"
echo "  🧠 Command     : $CMD"

# Log to file
{
  echo "Process $PID Details - $(date)"
  echo "-----------------------------------"
  echo "Start Time  : $START_TIME"
  echo "Elapsed Time: $ELAPSED_TIME"
  echo "User        : $USER"
  echo "Command     : $CMD"
  echo
} > "$LOGPATH"

echo "📄 Info logged to: $LOGPATH"
