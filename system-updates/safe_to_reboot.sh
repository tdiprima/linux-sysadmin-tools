#!/usr/bin/env bash
# ============================================================================
# safe_to_reboot.sh — Pre-reboot safety check for Ubuntu
# Run as root or with sudo for full visibility.
# Exit code 0 = safe to reboot, 1 = warnings found, 2 = critical issues found.
#
# Always check these first before rebooting: ✅
# - System load and memory use. 📊
# - Disk space and inodes. 💾
# - Active services and errors. ⚙️
# - Recent logs for patterns. 📝
# ============================================================================

set -euo pipefail

# ── Colours & symbols ───────────────────────────────────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; RST='\033[0m'
PASS="${GRN}✔${RST}"; WARN="${YEL}⚠${RST}"; FAIL="${RED}✘${RST}"

# ── Thresholds (tweak to taste) ─────────────────────────────────────────────
LOAD_WARN_FACTOR=2        # warn if 1-min load > cores × this factor
MEM_WARN_PCT=90           # warn if RAM usage ≥ this %
SWAP_WARN_PCT=80          # warn if swap usage ≥ this %
DISK_WARN_PCT=90          # warn if any mount ≥ this %
DISK_CRIT_PCT=97          # critical if any mount ≥ this %
INODE_WARN_PCT=90         # warn if inode usage ≥ this %
FAILED_SVC_LIMIT=0        # any failed units = warning
LOG_ERROR_WINDOW=30       # minutes of recent logs to scan

# ── Counters ────────────────────────────────────────────────────────────────
warnings=0; criticals=0

banner() { echo -e "\n${BLD}${CYN}── $1 ──${RST}"; }
ok()     { echo -e "  ${PASS}  $1"; }
warn()   { echo -e "  ${WARN}  ${YEL}$1${RST}"; ((warnings++)) || true; }
crit()   { echo -e "  ${FAIL}  ${RED}$1${RST}"; ((criticals++)) || true; }

# ════════════════════════════════════════════════════════════════════════════
# 1. SYSTEM LOAD & MEMORY
# ════════════════════════════════════════════════════════════════════════════
banner "📊  System Load & Memory"

cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
read -r load1 load5 load15 _ < /proc/loadavg
threshold=$(awk "BEGIN{printf \"%.1f\", $cores * $LOAD_WARN_FACTOR}")

echo -e "  Cores: ${BLD}$cores${RST}  |  Load (1/5/15): ${BLD}$load1 $load5 $load15${RST}"
if awk "BEGIN{exit !($load1 > $threshold)}"; then
    warn "1-min load ($load1) exceeds ${threshold} (${cores} cores × ${LOAD_WARN_FACTOR})"
else
    ok "Load is within normal range"
fi

# Memory
read -r mem_total mem_avail <<< "$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print t, a}' /proc/meminfo)"
mem_used_pct=$(awk "BEGIN{printf \"%d\", 100 - ($mem_avail/$mem_total*100)}")
mem_total_h=$(awk "BEGIN{printf \"%.1f\", $mem_total/1048576}")
mem_avail_h=$(awk "BEGIN{printf \"%.1f\", $mem_avail/1048576}")

echo -e "  RAM: ${BLD}${mem_used_pct}%${RST} used  (${mem_avail_h} GB free / ${mem_total_h} GB total)"
if (( mem_used_pct >= MEM_WARN_PCT )); then
    warn "Memory usage is high (${mem_used_pct}% ≥ ${MEM_WARN_PCT}%)"
else
    ok "Memory usage is healthy"
fi

# Swap
if swapon --show --noheadings 2>/dev/null | grep -q .; then
    read -r sw_total sw_free <<< "$(awk '/SwapTotal/{t=$2} /SwapFree/{f=$2} END{print t, f}' /proc/meminfo)"
    if (( sw_total > 0 )); then
        sw_used_pct=$(awk "BEGIN{printf \"%d\", 100 - ($sw_free/$sw_total*100)}")
        echo -e "  Swap: ${BLD}${sw_used_pct}%${RST} used"
        if (( sw_used_pct >= SWAP_WARN_PCT )); then
            warn "Swap usage is high (${sw_used_pct}% ≥ ${SWAP_WARN_PCT}%)"
        else
            ok "Swap usage is fine"
        fi
    fi
else
    echo -e "  Swap: none configured"
fi

# ════════════════════════════════════════════════════════════════════════════
# 2. DISK SPACE & INODES
# ════════════════════════════════════════════════════════════════════════════
banner "💾  Disk Space"

while read -r fs size used avail pct mount; do
    pct_num=${pct%\%}
    label="${mount} (${fs}): ${used}/${size} — ${pct} full"
    if (( pct_num >= DISK_CRIT_PCT )); then
        crit "$label  [CRITICAL]"
    elif (( pct_num >= DISK_WARN_PCT )); then
        warn "$label"
    else
        ok "$label"
    fi
done < <(df -hP -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | tail -n +2)

banner "💾  Inode Usage"

while read -r fs itotal iused ifree pct mount; do
    pct_num=${pct%\%}
    if [[ "$pct_num" =~ ^[0-9]+$ ]]; then
        if (( pct_num >= INODE_WARN_PCT )); then
            warn "${mount}: inodes ${pct} used (${iused}/${itotal})"
        else
            ok "${mount}: inodes ${pct} used"
        fi
    fi
done < <(df -iP -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | tail -n +2)

# ════════════════════════════════════════════════════════════════════════════
# 3. ACTIVE SERVICES, FAILED UNITS & KEY PROCESSES
# ════════════════════════════════════════════════════════════════════════════
banner "⚙️   Services & Processes"

# Failed systemd units
if command -v systemctl &>/dev/null; then
    failed_units=$(systemctl --no-legend --state=failed 2>/dev/null || true)
    #failed_count=$(echo "$failed_units" | grep -c '[^ ]' || true)
    #if (( failed_count > FAILED_SVC_LIMIT )); then
    #    warn "${failed_count} failed systemd unit(s):"
    #    echo "$failed_units" | while read -r line; do
    #        echo -e "        ${RED}${line}${RST}"
    #    done
    if [[ -n "$failed_units" ]]; then
        failed_count=$(echo "$failed_units" | wc -l)
    else
        failed_count=0
    fi
    if (( failed_count > FAILED_SVC_LIMIT )); then
        warn "${failed_count} failed systemd unit(s):"
        while read -r line; do
            echo -e "        ${RED}${line}${RST}"
        done <<< "$failed_units"
    else
        ok "No failed systemd units"
    fi

    # Check for running unattended-upgrades / dpkg / apt
    if pgrep -x unattended-upgr &>/dev/null || pgrep -x dpkg &>/dev/null || pgrep -af "apt.*(install|upgrade|dist-upgrade)" &>/dev/null; then
        warn "Package manager (apt/dpkg/unattended-upgrades) is running — rebooting may leave packages in a broken state"
    else
        ok "No active package operations"
    fi
else
    warn "systemctl not found — skipping unit checks"
fi

# Pending reboot required?
if [[ -f /var/run/reboot-required ]]; then
    ok "Reboot required flag is set (/var/run/reboot-required)"
    if [[ -f /var/run/reboot-required.pkgs ]]; then
        echo -e "     Packages requesting reboot:"
        sed 's/^/        /' /var/run/reboot-required.pkgs
    fi
fi

# Active SSH sessions
ssh_sessions=$(who 2>/dev/null | grep -c 'pts/' || true)
if (( ssh_sessions > 1 )); then
    warn "${ssh_sessions} active terminal sessions (other users may be connected)"
    who 2>/dev/null | grep 'pts/' | sed 's/^/        /'
elif (( ssh_sessions == 1 )); then
    ok "1 active terminal session (likely just you)"
else
    ok "No remote terminal sessions"
fi

# NFS / CIFS mounts
if mount | grep -qE 'type (nfs|cifs)'; then
    warn "Network filesystems are mounted — ensure they can be cleanly unmounted"
    mount | grep -E 'type (nfs|cifs)' | sed 's/^/        /'
else
    ok "No NFS/CIFS mounts"
fi

# ════════════════════════════════════════════════════════════════════════════
# 4. RECENT LOGS — ERROR PATTERNS
# ════════════════════════════════════════════════════════════════════════════
banner "📝  Recent Logs (last ${LOG_ERROR_WINDOW} min)"

if command -v journalctl &>/dev/null; then
    err_count=$(journalctl --since "-${LOG_ERROR_WINDOW}min" -p err --no-pager -q 2>/dev/null | wc -l || echo 0)
    if (( err_count > 20 )); then
        warn "${err_count} error-level entries in the last ${LOG_ERROR_WINDOW} min (showing last 10):"
        journalctl --since "-${LOG_ERROR_WINDOW}min" -p err --no-pager -q 2>/dev/null | tail -10 | sed 's/^/        /'
    elif (( err_count > 0 )); then
        warn "${err_count} error-level entries in the last ${LOG_ERROR_WINDOW} min:"
        journalctl --since "-${LOG_ERROR_WINDOW}min" -p err --no-pager -q 2>/dev/null | tail -5 | sed 's/^/        /'
    else
        ok "No error-level log entries"
    fi

    # OOM killer
    oom=$(journalctl --since "-${LOG_ERROR_WINDOW}min" --no-pager -q 2>/dev/null | grep -ci 'oom.kill\|out of memory' || true)
    if (( oom > 0 )); then
        crit "OOM killer fired ${oom} time(s) recently — investigate before rebooting"
    else
        ok "No OOM events"
    fi

    # Disk I/O errors
    ioerr=$(journalctl --since "-${LOG_ERROR_WINDOW}min" --no-pager -q 2>/dev/null | grep -ci 'I/O error\|blk_update_request' || true)
    if (( ioerr > 0 )); then
        crit "Disk I/O errors detected (${ioerr}) — check hardware health before rebooting"
    else
        ok "No disk I/O errors"
    fi
else
    warn "journalctl not available — skipping log analysis"
fi

# ════════════════════════════════════════════════════════════════════════════
# 5. UPTIME & KERNEL
# ════════════════════════════════════════════════════════════════════════════
banner "ℹ️   System Info"

echo -e "  Hostname : ${BLD}$(hostname)${RST}"
echo -e "  Kernel   : ${BLD}$(uname -r)${RST}"
echo -e "  Uptime   : ${BLD}$(uptime -p 2>/dev/null || uptime)${RST}"

# ════════════════════════════════════════════════════════════════════════════
# VERDICT
# ════════════════════════════════════════════════════════════════════════════
banner "🏁  Verdict"

if (( criticals > 0 )); then
    echo -e "  ${FAIL}  ${RED}${BLD}${criticals} CRITICAL issue(s) found — reboot is NOT recommended.${RST}"
    echo -e "  ${RED}     Resolve the issues above before rebooting.${RST}"
    exit 2
elif (( warnings > 0 )); then
    echo -e "  ${WARN}  ${YEL}${BLD}${warnings} warning(s) found — reboot is probably OK, but review above.${RST}"
    exit 1
else
    echo -e "  ${PASS}  ${GRN}${BLD}All checks passed — safe to reboot! 🎉${RST}"
    exit 0
fi
