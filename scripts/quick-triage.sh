#!/bin/bash
# Battle-ready "oh 💩" IR triage script
# ./triage.sh | tee triage_$(date +%F_%T).log

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
NC="\033[0m"

echo
echo -e "${MAGENTA}========== QUICK IR TRIAGE ==========${NC}"
date

echo
echo -e "${BLUE}[*] Recent logins:${NC}"
last -a | head -n 10

echo
echo -e "${YELLOW}[*] Failed login attempts:${NC}"
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -n 10

echo
echo -e "${YELLOW}[*] Successful sudo usage:${NC}"
grep "sudo:" /var/log/auth.log 2>/dev/null | tail -n 10

echo
echo -e "${CYAN}[*] Currently logged in users:${NC}"
who

echo
echo -e "${YELLOW}[*] Suspicious running processes (top CPU):${NC}"
ps aux --sort=-%cpu | head -n 10

echo
echo -e "${YELLOW}[*] Suspicious running processes (non-system users):${NC}"
ps aux | awk '$1 != "root" && $1 != "postgres"'

echo
echo -e "${GREEN}[*] Recently modified files (/var/www):${NC}"
find /var/www/ -type f -mtime -1 2>/dev/null

echo
echo -e "${GREEN}[*] Recently modified system files (/etc):${NC}"
find /etc -type f -mtime -1 2>/dev/null

echo
echo -e "${RED}[*] Outbound network connections:${NC}"
ss -antp | grep ESTAB | grep -v 127.0.0.1

echo
echo -e "${RED}[*] Listening ports:${NC}"
ss -tulnp

echo
echo -e "${MAGENTA}[*] New user accounts (UID >= 1000):${NC}"
awk -F: '$3 >= 1000 {print $1 ":" $3}' /etc/passwd

echo
echo -e "${MAGENTA}[*] Cron jobs:${NC}"
crontab -l 2>/dev/null
ls -lah /etc/cron* 2>/dev/null

# Well...
# echo
# echo -e "${MAGENTA}[*] Last 10 commands (bash history):${NC}"
# tail -n 10 ~/.bash_history 2>/dev/null

echo
echo -e "${MAGENTA}========== END TRIAGE ==========${NC}"
echo
