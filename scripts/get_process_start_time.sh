#!/bin/bash

# ============================================
# Script: get_process_start_time.sh
# Description:
#   Given a PID, this script:
#     1. Checks if the process is running.
#     2. If running, prints its full start time.
#     3. If not running, prints a helpful message.
#
# Usage:
#   ./get_process_start_time.sh <PID>
# ============================================

PID="$1"

# Check if a PID was passed
if [[ -z "$PID" ]]; then
  echo "❌ Error: No PID provided."
  echo "Usage: $0 <PID>"
  exit 1
fi

# Check if process exists
if ! ps -p "$PID" > /dev/null 2>&1; then
  echo "❌ Process with PID $PID is not running."
  exit 1
fi

# Get the full start time
START_TIME=$(ps -p "$PID" -o lstart=)

if [[ -z "$START_TIME" ]]; then
  echo "⚠️  Unable to determine start time for PID $PID (possibly short-lived or zombie process)."
  exit 2
fi

echo "✅ Process $PID started at: $START_TIME"
