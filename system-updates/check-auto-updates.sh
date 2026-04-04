#!/usr/bin/env bash
#
# check-auto-updates.sh
# Checks whether unattended-upgrades (Ubuntu) or dnf-automatic (RHEL) is
# installed, enabled, and actually running — with color-coded output.
#
# Usage: sudo ./check-auto-updates.sh
# (Some checks require root to read logs or configs fully)

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────

pass() { echo -e "  ${GREEN}✔${RESET}  $*"; }
fail() { echo -e "  ${RED}✘${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
info() { echo -e "  ${CYAN}→${RESET}  $*"; }
section() { echo -e "\n${BOLD}${CYAN}=== $* ===${RESET}"; }

# Check if a systemd unit is enabled
is_enabled() {
    local unit="$1"
    systemctl is-enabled --quiet "${unit}" 2>/dev/null
}

# Check if a systemd unit is active (running or waiting for timer)
is_active() {
    local unit="$1"
    systemctl is-active --quiet "${unit}" 2>/dev/null
}

# Print the last-triggered time for a timer unit
show_timer_last_run() {
    local timer="$1"
    local last_run
    last_run=$(systemctl show "${timer}" --property=LastTriggerUSec 2>/dev/null \
        | cut -d= -f2)
    if [[ -z "${last_run}" || "${last_run}" == "n/a" ]]; then
        warn "Last trigger time unavailable"
    else
        info "Last triggered: ${last_run}"
    fi
}

# ── Detect distro ─────────────────────────────────────────────────────────────

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID}"
    else
        echo "unknown"
    fi
}

# ── Ubuntu: unattended-upgrades ───────────────────────────────────────────────

check_unattended_upgrades() {
    section "unattended-upgrades (Ubuntu/Debian)"

    # 1. Package installed?
    if ! dpkg -s unattended-upgrades &>/dev/null; then
        fail "Package 'unattended-upgrades' is NOT installed"
        return
    fi
    pass "Package installed"

    # 2. Apt auto-upgrade config enabled?
    local config_file="/etc/apt/apt.conf.d/20auto-upgrades"
    if [[ ! -f "${config_file}" ]]; then
        fail "Config file missing: ${config_file}"
    else
        local periodic_update periodic_upgrade
        periodic_update=$(grep -i 'APT::Periodic::Update-Package-Lists' "${config_file}" \
            | grep -o '"[0-9]*"' | tr -d '"')
        periodic_upgrade=$(grep -i 'APT::Periodic::Unattended-Upgrade' "${config_file}" \
            | grep -o '"[0-9]*"' | tr -d '"')

        if [[ "${periodic_update}" == "1" ]]; then
            pass "APT::Periodic::Update-Package-Lists = 1"
        else
            fail "APT::Periodic::Update-Package-Lists is not set to 1 (got: '${periodic_update}')"
        fi

        if [[ "${periodic_upgrade}" == "1" ]]; then
            pass "APT::Periodic::Unattended-Upgrade = 1"
        else
            fail "APT::Periodic::Unattended-Upgrade is not set to 1 (got: '${periodic_upgrade}')"
        fi
    fi

    # 3. Service running?
    if is_active "unattended-upgrades"; then
        pass "Service is active"
    else
        fail "Service is NOT active"
    fi

    if is_enabled "unattended-upgrades"; then
        pass "Service is enabled (survives reboot)"
    else
        warn "Service is NOT enabled on boot"
    fi

    # 4. Daily timers
    for timer in apt-daily.timer apt-daily-upgrade.timer; do
        if is_active "${timer}"; then
            pass "Timer active: ${timer}"
            show_timer_last_run "${timer}"
        else
            fail "Timer NOT active: ${timer}"
        fi
    done

    # 5. Recent log activity
    local log_dir="/var/log/unattended-upgrades"
    local log_file="${log_dir}/unattended-upgrades.log"

    if [[ -f "${log_file}" ]]; then
        local last_entry
        last_entry=$(tail -n 1 "${log_file}" 2>/dev/null)
        if [[ -n "${last_entry}" ]]; then
            pass "Log file exists and has entries"
            info "Last log entry: ${last_entry}"
        else
            warn "Log file exists but is empty"
        fi
    elif [[ -d "${log_dir}" ]]; then
        # Log file is only written when packages are actually upgraded.
        # The directory existing but the file missing means the service ran
        # but found nothing to upgrade — check journald to confirm.
        warn "No upgrade log yet (system may be fully up to date)"
    else
        warn "Log directory missing: ${log_dir}"
    fi

    # The real upgrade work runs inside apt-daily-upgrade.service (triggered by
    # apt-daily-upgrade.timer). unattended-upgrades.service is only a shutdown hook.
    local last_journal
    last_journal=$(journalctl -u apt-daily-upgrade.service --no-pager -n 6 2>/dev/null \
        | grep -v '^$' | tail -n 6)
    if [[ -n "${last_journal}" ]]; then
        pass "journald has entries for apt-daily-upgrade.service"
        info "Last 6 journal lines:"
        while IFS= read -r line; do
            echo "       ${line}"
        done <<< "${last_journal}"
    else
        warn "No journald entries for apt-daily-upgrade.service — may not have run yet"
    fi
}

# ── RHEL/CentOS: dnf-automatic ────────────────────────────────────────────────

check_dnf_automatic() {
    section "dnf-automatic (RHEL/CentOS/Fedora)"

    # 1. Package installed?
    if ! rpm -q dnf-automatic &>/dev/null; then
        fail "Package 'dnf-automatic' is NOT installed"
        return
    fi
    pass "Package installed"

    # 2. Config: apply_updates enabled?
    local config_file="/etc/dnf/automatic.conf"
    if [[ ! -f "${config_file}" ]]; then
        fail "Config file missing: ${config_file}"
    else
        local apply_updates
        apply_updates=$(grep -i '^apply_updates' "${config_file}" \
            | awk -F'=' '{print $2}' | tr -d ' ')
        if [[ "${apply_updates,,}" == "yes" ]]; then
            pass "apply_updates = yes"
        else
            warn "apply_updates = '${apply_updates}' (updates will be downloaded but NOT applied)"
        fi

        local upgrade_type
        upgrade_type=$(grep -i '^upgrade_type' "${config_file}" \
            | awk -F'=' '{print $2}' | tr -d ' ')
        info "upgrade_type = ${upgrade_type:-default}"
    fi

    # 3. Timer active?
    local timer="dnf-automatic.timer"
    if is_active "${timer}"; then
        pass "Timer is active: ${timer}"
        show_timer_last_run "${timer}"
    else
        fail "Timer is NOT active: ${timer}"
    fi

    if is_enabled "${timer}"; then
        pass "Timer is enabled (survives reboot)"
    else
        warn "Timer is NOT enabled on boot"
    fi

    # 4. Recent journal entries
    local last_journal
    last_journal=$(journalctl -u dnf-automatic --no-pager -n 3 2>/dev/null \
        | tail -n 3)
    if [[ -n "${last_journal}" ]]; then
        pass "Recent journal entries found"
        info "Last 3 lines from journalctl:"
        while IFS= read -r line; do
            echo "       ${line}"
        done <<< "${last_journal}"
    else
        warn "No journal entries found for dnf-automatic (may not have run yet)"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    echo -e "\n${BOLD}Auto-Update Health Check${RESET}"
    echo -e "Host: $(hostname)  |  Date: $(date)"

    local distro
    distro=$(detect_distro)
    info "Detected distro ID: ${distro}"

    case "${distro}" in
        ubuntu|debian|linuxmint|pop)
            check_unattended_upgrades
            ;;
        rhel|centos|fedora|rocky|almalinux|ol)
            check_dnf_automatic
            ;;
        *)
            warn "Unrecognized distro '${distro}' — running both checks"
            check_unattended_upgrades
            check_dnf_automatic
            ;;
    esac

    echo ""
}

main "$@"
