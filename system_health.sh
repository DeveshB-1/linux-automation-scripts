#!/bin/bash
# system_health.sh - Comprehensive system health check for RHEL/CentOS
# Usage: ./system_health.sh [--alert-email admin@example.com]

set -euo pipefail

ALERT_EMAIL=${1:-""}
LOG_FILE="/var/log/health_check.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ERRORS=()

log() { echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"; }
alert() { ERRORS+=("$1"); log "ALERT: $1"; }

# CPU check
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%us,')
CPU_USED=$(echo "100 - $CPU_IDLE" | bc)
log "CPU Usage: ${CPU_USED}%"
[ $(echo "$CPU_USED > 85" | bc) -eq 1 ] && alert "High CPU: ${CPU_USED}%"

# Memory check
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
MEM_USED=$(free -m | awk '/^Mem:/{print $3}')
MEM_PCT=$(echo "scale=1; $MEM_USED * 100 / $MEM_TOTAL" | bc)
log "Memory Usage: ${MEM_PCT}% (${MEM_USED}MB / ${MEM_TOTAL}MB)"
[ $(echo "$MEM_PCT > 90" | bc) -eq 1 ] && alert "High Memory: ${MEM_PCT}%"

# Disk check
while IFS= read -r line; do
    USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')
    log "Disk $MOUNT: ${USAGE}%"
    [ "$USAGE" -gt 80 ] && alert "High Disk on $MOUNT: ${USAGE}%"
done < <(df -h | tail -n +2 | grep -v tmpfs)

# Critical services check
for SVC in nginx docker sshd firewalld; do
    if systemctl is-active --quiet "$SVC" 2>/dev/null; then
        log "Service $SVC: active"
    else
        alert "Service $SVC is NOT running"
    fi
done

# Load average check
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
log "Load Average (1m): $LOAD"

# Summary
if [ ${#ERRORS[@]} -eq 0 ]; then
    log "Health check PASSED - all systems normal"
    exit 0
else
    log "Health check FAILED - ${#ERRORS[@]} alerts"
    if [ -n "$ALERT_EMAIL" ]; then
        echo "${ERRORS[*]}" | mail -s "Server Alert: $(hostname)" "$ALERT_EMAIL"
    fi
    exit 1
fi
