#!/bin/bash

# ─────────────────────────────────────────────
#  Firewall Rule Generator
#  Supports: ufw, iptables, firewall-cmd
# ─────────────────────────────────────────────

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Helpers ──────────────────────────────────

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║       🔥 Firewall Rule Generator         ║${RESET}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${RESET}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${CYAN}── $1 ──────────────────────────────────────${RESET}"
    echo ""
}

print_cmd() {
    echo -e "  ${GREEN}${BOLD}\$${RESET} ${YELLOW}$1${RESET}"
}

print_note() {
    echo -e "  ${DIM}↳ $1${RESET}"
}

print_error() {
    echo -e "  ${RED}✖ $1${RESET}"
}

# ─── Validate IP ──────────────────────────────

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if (( octet > 255 )); then return 1; fi
        done
        return 0
    fi
    return 1
}

# ─── Validate Port ────────────────────────────

validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 )); then
        return 0
    fi
    return 1
}

# ─── Main ─────────────────────────────────────

print_header

# Get IP
while true; do
    echo -e "${BOLD}Enter the source IP address to allow:${RESET}"
    read -rp "  IP: " IP
    if validate_ip "$IP"; then
        break
    else
        print_error "Invalid IP address. Please try again."
    fi
done

echo ""

# Get Port
while true; do
    echo -e "${BOLD}Enter the destination port number:${RESET}"
    echo -e "  ${DIM}(e.g. 22 for SSH, 80 for HTTP, 443 for HTTPS)${RESET}"
    read -rp "  Port: " PORT
    if validate_port "$PORT"; then
        break
    else
        print_error "Invalid port. Must be a number between 1 and 65535."
    fi
done

echo ""

# Get Action
echo -e "${BOLD}Do you want to ADD or REMOVE this rule?${RESET}"
echo -e "  ${MAGENTA}1)${RESET} Add rule"
echo -e "  ${MAGENTA}2)${RESET} Remove rule"
echo ""
while true; do
    read -rp "  Choice [1-2]: " ACTION_CHOICE
    case $ACTION_CHOICE in
        1) ACTION="add"; break ;;
        2) ACTION="remove"; break ;;
        *) print_error "Please enter 1 or 2." ;;
    esac
done

echo ""

# Get Policy
if [ "$ACTION" = "add" ]; then
    echo -e "${BOLD}Should this rule ALLOW or DENY the traffic?${RESET}"
else
    echo -e "${BOLD}Was this rule originally an ALLOW or DENY?${RESET}"
fi
echo -e "  ${MAGENTA}1)${RESET} Allow / Accept"
echo -e "  ${MAGENTA}2)${RESET} Deny / Reject"
echo ""
while true; do
    read -rp "  Choice [1-2]: " POLICY_CHOICE
    case $POLICY_CHOICE in
        1) POLICY="allow"; break ;;
        2) POLICY="deny";  break ;;
        *) print_error "Please enter 1 or 2." ;;
    esac
done

echo ""

# Get Firewall Type
echo -e "${BOLD}Select firewall type:${RESET}"
echo -e "  ${MAGENTA}1)${RESET} ufw"
echo -e "  ${MAGENTA}2)${RESET} iptables"
echo -e "  ${MAGENTA}3)${RESET} firewall-cmd (firewalld)"
echo -e "  ${MAGENTA}4)${RESET} All three"
echo ""
while true; do
    read -rp "  Choice [1-4]: " CHOICE
    case $CHOICE in
        1|2|3|4) break ;;
        *) print_error "Please enter 1, 2, 3, or 4." ;;
    esac
done

# ─── Output Rules ─────────────────────────────

ACTION_LABEL=$([ "$ACTION" = "add" ] && echo "ADD Rule" || echo "REMOVE Rule")

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${BLUE}║        Generated Commands: ${ACTION_LABEL}        ║${RESET}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${RESET}"

show_ufw() {
    print_section "UFW"
    if [ "$ACTION" = "add" ]; then
        if [ "$POLICY" = "allow" ]; then
            echo -e "  ${BOLD}Allow rule:${RESET}"
            print_cmd "sudo ufw allow from $IP to any port $PORT"
        else
            echo -e "  ${BOLD}${RED}Deny rule:${RESET}"
            print_cmd "sudo ufw deny from $IP to any port $PORT"
            print_note "ufw \'deny\' silently drops packets. Use \'reject\' to send an error back to the sender:"
            print_cmd "sudo ufw reject from $IP to any port $PORT"
        fi
        echo ""
        echo -e "  ${BOLD}Reload firewall:${RESET}"
        print_cmd "sudo ufw reload"
        print_note "ufw rules are persistent across reboots — no extra save step needed."
    else
        echo -e "  ${BOLD}${RED}Remove rule:${RESET}"
        print_note "First, find the rule number:"
        print_cmd "sudo ufw status numbered"
        echo ""
        print_note "Then delete by number (e.g. if it is rule 3):"
        print_cmd "sudo ufw delete 3"
        echo ""
        print_note "Or delete by rule spec directly:"
        if [ "$POLICY" = "allow" ]; then
            print_cmd "sudo ufw delete allow from $IP to any port $PORT"
        else
            print_cmd "sudo ufw delete deny from $IP to any port $PORT"
        fi
        echo ""
        echo -e "  ${BOLD}Reload firewall:${RESET}"
        print_cmd "sudo ufw reload"
    fi
    echo ""
    echo -e "  ${BOLD}View all rules (numbered):${RESET}"
    print_cmd "sudo ufw status numbered"
}

show_iptables() {
    print_section "iptables"
    if [ "$ACTION" = "add" ]; then
        if [ "$POLICY" = "allow" ]; then
            echo -e "  ${BOLD}Allow rule:${RESET}"
            print_cmd "sudo iptables -A INPUT -s $IP -p tcp --dport $PORT -j ACCEPT"
        else
            echo -e "  ${BOLD}${RED}Deny rule:${RESET}"
            print_cmd "sudo iptables -A INPUT -s $IP -p tcp --dport $PORT -j DROP"
            print_note "DROP silently discards packets. Use REJECT to send an error back to the sender:"
            print_cmd "sudo iptables -A INPUT -s $IP -p tcp --dport $PORT -j REJECT"
        fi
        print_note "Takes effect immediately — no reload needed."
    else
        if [ "$POLICY" = "allow" ]; then
            IPT_TARGET="ACCEPT"
        else
            IPT_TARGET="DROP"
        fi
        echo -e "  ${BOLD}${RED}Remove rule:${RESET}"
        print_note "First, find the rule number:"
        print_cmd "sudo iptables -L INPUT -v -n --line-numbers"
        echo ""
        print_note "Then delete by line number (e.g. if it is line 3):"
        print_cmd "sudo iptables -D INPUT 3"
        echo ""
        print_note "Or delete by matching the rule spec directly:"
        print_cmd "sudo iptables -D INPUT -s $IP -p tcp --dport $PORT -j $IPT_TARGET"
        print_note "Takes effect immediately — no reload needed."
    fi
    echo ""
    echo -e "  ${BOLD}View all rules (numbered):${RESET}"
    print_cmd "sudo iptables -L -v -n --line-numbers"
    echo ""
    echo -e "  ${BOLD}Persist rules across reboots (choose one):${RESET}"
    print_cmd "sudo iptables-save | sudo tee /etc/iptables/rules.v4"
    echo -e "  ${DIM}  — or, if iptables-persistent is installed: —${RESET}"
    print_cmd "sudo netfilter-persistent save"
    print_note "netfilter-persistent saves both IPv4 (rules.v4) and IPv6 (rules.v6)."
}

show_firewalld() {
    print_section "firewall-cmd (firewalld)"
    if [ "$POLICY" = "allow" ]; then
        FWD_VERDICT="accept"
    else
        FWD_VERDICT="reject"
    fi
    if [ "$ACTION" = "add" ]; then
        if [ "$POLICY" = "allow" ]; then
            echo -e "  ${BOLD}Allow rule:${RESET}"
        else
            echo -e "  ${BOLD}${RED}Deny rule:${RESET}"
            print_note "firewalld uses \'reject\' (sends error back) or \'drop\' (silent). Using reject:"
        fi
        print_cmd "sudo firewall-cmd --permanent --add-rich-rule='rule family=\"ipv4\" source address=\"$IP\" port protocol=\"tcp\" port=\"$PORT\" $FWD_VERDICT'"
        if [ "$POLICY" = "deny" ]; then
            print_note "For silent drop instead, replace \'reject\' with \'drop\' in the rule above."
        fi
    else
        echo -e "  ${BOLD}${RED}Remove rule:${RESET}"
        print_cmd "sudo firewall-cmd --permanent --remove-rich-rule='rule family=\"ipv4\" source address=\"$IP\" port protocol=\"tcp\" port=\"$PORT\" $FWD_VERDICT'"
    fi
    echo ""
    echo -e "  ${BOLD}View all rules:${RESET}"
    print_cmd "sudo firewall-cmd --list-all"
    print_note "Add --permanent to see saved rules instead of active ones."
    echo ""
    echo -e "  ${BOLD}Reload firewall (required to apply --permanent rules):${RESET}"
    print_cmd "sudo firewall-cmd --reload"
    print_note "Rules marked --permanent survive reboots automatically."
}

case $CHOICE in
    1) show_ufw ;;
    2) show_iptables ;;
    3) show_firewalld ;;
    4) show_ufw; show_iptables; show_firewalld ;;
esac

echo ""
echo -e "${BOLD}${BLUE}────────────────────────────────────────────${RESET}"
ACTION_UPPER=$(echo "$ACTION" | tr '[:lower:]' '[:upper:]')
POLICY_UPPER=$(echo "$POLICY" | tr '[:lower:]' '[:upper:]')
echo -e "${DIM}  Action: ${ACTION_UPPER}  |  Policy: ${POLICY_UPPER}  |  IP: $IP  |  Port: $PORT  |  Protocol: TCP${RESET}"
echo -e "${BOLD}${BLUE}────────────────────────────────────────────${RESET}"
echo ""
