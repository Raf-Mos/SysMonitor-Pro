#!/bin/bash
set -euo pipefail
# Fonctions à implémenter dans lib/system_monitor.sh
# monitor_cpu_usage()      # Utilisation CPU avec seuils
# monitor_memory_usage()   # Consommation RAM et SWAP
# monitor_disk_space()     # Espace disque par partition
# monitor_system_load()    # Load average et nombre de processus

# Utilisation CPU avec seuils
# monitor_cpu_usage() {
#     echo "=== Surveillance de l'utilisation CPU ==="
#     CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
#     echo "Utilisation CPU actuelle: $CPU_USAGE%"

#     if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
#         echo "Alerte: Utilisation CPU élevée!"
#     elif (( $(echo "$CPU_USAGE > 50" | bc -l) )); then
#         echo "Attention: Utilisation CPU modérée."
#     else
#         echo "Utilisation CPU normale."
#     fi

# }

monitor_cpu_usage() {
    echo "=== Surveillance de l'utilisation CPU ==="
    local idle
    local usage

    idle=$(top -bn1 | grep "Cpu(s)" | grep -oP '\d+\.\d+(?= ?id)')
    usage=$(printf "%.1f" $(echo "100 - $idle" | bc))

    local status="✅ OK"
    if (( $(echo "$usage >= ${CPU_CRIT:-90}" | bc -l) )); then
        status="❌ CRITICAL"
    elif (( $(echo "$usage >= ${CPU_WARN:-70}" | bc -l) )); then
        status="⚠️ WARNING"
    fi

    echo "Utilisation CPU actuelle: $usage% (${status})"
    echo "Idle CPU actuelle: $idle%"
    echo ""
}

monitor_memory_usage() {
    echo "=== Surveillance de l'utilisation de la mémoire ==="
  local mem_info
  mem_info=$(free -m | awk '/Mem:/{printf "%.2f%% (%.0f MB / %.0f MB)", $3/$2*100, $3, $2}')
  local swap_info
  swap_info=$(free -m | awk '/Swap:/{printf "%.2f%% (%.0f MB / %.0f MB)", $3/$2*100, $3, $2}')
  echo "Mémoire: ${mem_info}, SWAP: ${swap_info}"
  echo ""
}

monitor_disk_space() {
  echo "=== Surveillance de l'espace disque ==="
  df -h --output=source,fstype,size,used,avail,pcent,target | grep -vE '^(tmpfs|udev|snapfuse|Filesystem|none)' | while read -r line; do
    local disk_usage
    disk_usage=$(echo "$line" | awk '{print $6}' | tr -d '%')

    if [[ -z "$disk_usage" || ! "$disk_usage" =~ ^[0-9]+$ ]]; then
      continue
    fi

    local level="✅ OK"
    if (( disk_usage >= ${DISK_CRIT:-90} )); then level="❌ CRITICAL"; elif (( disk_usage >= ${DISK_WARN:-70} )); then level="⚠️  WARNING"; fi
    echo "$line (${level})"
  done
  echo ""
}

# monitor_disk_space() {
#   echo "=== Surveillance de l'espace disque ==="
#   df -h | grep -vE '^(Filesystem|none|tmpfs|snapfuse)'
# }

monitor_system_load() {
    echo "=== Surveillance de la charge système ==="
  local load
  load=$(uptime | awk -F'load average:' '{ print $2 }')
  local procs
  procs=$(ps aux --no-heading | wc -l)
  echo "Load Average: ${load}"
  echo "Nombre de processus: ${procs}"
  local load_value
  load_value=$(echo "$load" | awk '{print int($1)}')
  local level="✅ OK"
  if (( load_value >= ${LOAD_CRIT:-5} )); then level="❌ CRITICAL"; elif (( load_value >= ${LOAD_WARN:-3} )); then level="⚠️  WARNING"; fi
  echo "Charge système (${level})"

}

run_system_monitor() {
  echo "=== Surveillance du système ==="
    echo ""
  monitor_cpu_usage
  monitor_memory_usage
  monitor_disk_space
  # monitor_system_load
}

echo "$(run_system_monitor)" 
$@