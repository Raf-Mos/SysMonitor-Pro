#!/bin/bash
set -euo pipefail

check_critical_services() {
    local any_failed=0
    for s in "${CRITICAL_SERVICES[@]}"; do
        if command -v systemctl >/dev/null 2>&1; then
            if systemctl is-active --quiet "$s" 2>/dev/null; then
                echo "$s: active"
            else
                echo "$s: inactive"
                any_failed=1
            fi
        else
            # Fallback: try pgrep on service name
            if pgrep -f "$s" >/dev/null 2>&1; then
                echo "$s: running (pgrep)"
            else
                echo "$s: unknown/not running"
                any_failed=1
            fi
        fi
    done
    return $any_failed
}

restart_failed_service() {
    local svc=$1
    local attempts=${2:-${SERVICE_RESTART_MAX_ATTEMPTS:-1}}
    local i=0
    if ! command -v systemctl >/dev/null 2>&1; then
        echo "restart_failed_service: systemctl not available" >&2
        return 2
    fi
    while (( i < attempts )); do
        ((i++))
        echo "Restarting $svc (attempt $i/$attempts)"
        systemctl restart "$svc" 2>/dev/null || true
        sleep 1
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo "$svc: restarted"
            return 0
        fi
    done
    echo "$svc: failed to restart after $attempts attempts" >&2
    return 1
}

check_service_logs() {
    local svc=$1
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -u "$svc" -n 50 --no-pager 2>/dev/null || echo "No journal data for $svc"
    else
        echo "journalctl not available; check /var/log for $svc logs" >&2
    fi
}

validate_service_config() {
    local svc=$1
    # Best-effort: when systemctl available, run 'systemctl show' to verify
    if command -v systemctl >/dev/null 2>&1; then
        systemctl show --property=Id --value "$svc" >/dev/null 2>&1 && echo "$svc: config appears OK" || echo "$svc: cannot validate (not found)"
    else
        echo "systemctl not available; cannot validate $svc config"
    fi
}

run_service_monitoring() {
    echo "=== Services critiques ==="
    check_critical_services || true
}

