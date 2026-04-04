#!/bin/bash

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m" # No Color

# Quick IR triage
echo
echo -e "${BLUE}[*] Recent logins:${NC}"
last -a | head -n 10

echo
echo -e "${YELLOW}[*] Suspicious running processes:${NC}"
ps aux | grep -v root | grep -v postgres
# ps aux --sort=-%cpu | head

echo
echo -e "${GREEN}[*] Recent changes in web directory:${NC}"
find /var/www/ -type f -mtime -1

echo
echo -e "${RED}[*] Outbound network connections:${NC}"
netstat -antp | grep ESTABLISHED | grep -v 127.0.0.1
# ss -antp
