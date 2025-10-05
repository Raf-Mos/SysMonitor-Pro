#!/bin/bash
set -euo pipefail

check_network_connectivity() {
    local timeout=${NETWORK_TIMEOUT:-5}
    for t in "${PING_TARGETS[@]}"; do
        if ping -c 1 -W "$timeout" "$t" >/dev/null 2>&1; then
            echo "$t: OK"
        else
            echo "$t: FAIL"
        fi
    done
}

monitor_network_interfaces() {
    if command -v ip >/dev/null 2>&1; then
        ip -br addr show || ip addr show
    else
        ifconfig -a 2>/dev/null || echo "No ip/ifconfig available"
    fi
}

check_open_ports() {
    if command -v ss >/dev/null 2>&1; then
        ss -tlnp 2>/dev/null | grep LISTEN || true
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep LISTEN || true
    else
        echo "No ss/netstat available"
    fi
}

# Simple network traffic sampling per-interface over 1 second (bytes)
monitor_network_traffic() {
    local iface
    if [[ -z "${NETWORK_INTERFACES[*]:-}" ]]; then
        # try to detect interfaces
        if command -v ip >/dev/null 2>&1; then
            NETWORK_INTERFACES=( $(ip -o link show | awk -F': ' '{print $2}' | cut -d@ -f1) )
        else
            NETWORK_INTERFACES=(lo)
        fi
    fi
    for iface in "${NETWORK_INTERFACES[@]}"; do
        # read rx/tx bytes from /sys/class/net
        if [[ -r "/sys/class/net/${iface}/statistics/rx_bytes" ]]; then
            local rx1 tx1 rx2 tx2
            rx1=$(cat /sys/class/net/${iface}/statistics/rx_bytes)
            tx1=$(cat /sys/class/net/${iface}/statistics/tx_bytes)
            sleep 1
            rx2=$(cat /sys/class/net/${iface}/statistics/rx_bytes)
            tx2=$(cat /sys/class/net/${iface}/statistics/tx_bytes)
            local rx_delta=$((rx2 - rx1))
            local tx_delta=$((tx2 - tx1))
            echo "${iface}: rx=${rx_delta} bytes/s, tx=${tx_delta} bytes/s"
        else
            echo "${iface}: stats unavailable"
        fi
    done
}

run_network_monitoring() {
    echo "=== Réseau: connectivité ==="; check_network_connectivity
    echo "=== Réseau: interfaces ==="; monitor_network_interfaces
    echo "=== Réseau: ports ==="; check_open_ports
    echo "=== Réseau: trafic (sample 1s) ==="; monitor_network_traffic
}