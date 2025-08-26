#!/bin/bash
# Description: Script to check network connectivity
# Author: tdiprima

HOSTS=("google.com" "github.com" "yahoo.com")

for host in "${HOSTS[@]}"; do
  echo "Pinging $host..."
  ping -c 2 "$host" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "$host is reachable."
  else
    echo "$host is not reachable."
  fi
done
