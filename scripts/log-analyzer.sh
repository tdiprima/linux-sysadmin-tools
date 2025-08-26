#!/bin/bash
# Description: Script to analyze logs
# Author: tdiprima

LOG_FILE="/path/to/logfile"

echo "Log Analyzer"
echo "1. Find error messages"
echo "2. Count log entries by date"
read -p "Choose an option [1-2]: " option

case $option in
  1)
    grep -i "error" "$LOG_FILE"
    ;;
  2)
    awk '{print $1}' "$LOG_FILE" | sort | uniq -c
    ;;
  *)
    echo "Invalid option!"
    ;;
esac
