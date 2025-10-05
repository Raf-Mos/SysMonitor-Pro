#!/bin/bash
set -euo pipefail

# Retourne un entier d'utilisation CPU (%) et affiche un état si les seuils sont définis
monitor_cpu_usage() {
  local idle usage status="OK"
  # Try mpstat first for more reliable idle value, fallback to top
  if command -v mpstat >/dev/null 2>&1; then
    idle=$(mpstat 1 1 | awk '/all/ {print $NF}' | tail -n1 || echo 0)
  else
    idle=$(top -bn1 | awk -F',' '/Cpu\(s\)/ {gsub(/id/,"",$4); print $4}' | awk '{print $1}' | tr -d '[:alpha:]' || echo 0)
  fi
  usage=$(printf '%.0f' "$(echo "100 - ${idle:-0}" | bc -l 2>/dev/null || echo 0)")

  # Report thresholds if available
  if [[ -n "${CPU_CRITICAL_THRESHOLD:-}" && -n "${CPU_WARNING_THRESHOLD:-}" ]]; then
    if (( usage >= CPU_CRITICAL_THRESHOLD )); then status="CRITICAL";
    elif (( usage >= CPU_WARNING_THRESHOLD )); then status="WARNING"; fi
  fi

  echo "${usage}%${status:+ (${status})}"
}

# Retourne consommation mémoire (RAM %) et SWAP (en MiB) si présent
monitor_memory_usage() {
  local mem_total mem_used mem_pct swap_total swap_used
  read -r _ mem_total mem_used _ < <(free -m | awk '/Mem:/{print $1,$2,$3,$4}') || true
  mem_pct=0
  if [[ -n "$mem_total" && "$mem_total" -gt 0 ]]; then
    mem_pct=$(( mem_used * 100 / mem_total ))
  fi
  read -r _ swap_total swap_used _ < <(free -m | awk '/Swap:/{print $1,$2,$3,$4}') || true
  printf "RAM: %s%%, SWAP: %sMiB/%sMiB\n" "$mem_pct" "${swap_used:-0}" "${swap_total:-0}"
}

# Parcourt les partitions et retourne une ligne par partition contenant utilisation et niveau (OK/WARNING/CRITICAL)
monitor_disk_space() {
  local status=0
  # POSIX df output; columns: Filesystem 1024-blocks Used Available Capacity Mounted on
  df -P -h 2>/dev/null | awk 'NR>1 && $1 ~ /^\// {for(i=1;i<=NF;i++){printf "%s ", $i}; print ""}' | while read -r line; do
    # Extract last field as mountpoint, and find percentage (something like 12%) in the line
    local mnt use fs
    mnt=$(echo "$line" | awk '{print $NF}')
    use=$(echo "$line" | grep -oE '[0-9]+%' | tail -n1 | tr -d '%')
    fs=$(echo "$line" | awk '{print $1}')
    [[ -z "$use" ]] && use=0
    local level=OK
    if [[ -n "${DISK_CRITICAL_THRESHOLD:-}" && $use -ge $DISK_CRITICAL_THRESHOLD ]]; then level=CRITICAL; fi
    if [[ -n "${DISK_WARNING_THRESHOLD:-}" && $use -ge $DISK_WARNING_THRESHOLD && $level == OK ]]; then level=WARNING; fi
    echo "${fs} on ${mnt}: ${use}% (${level})"
    if [[ "$level" == CRITICAL ]]; then status=2; fi
    if [[ "$level" == WARNING && $status -eq 0 ]]; then status=1; fi
  done

  # Also report Windows drives (WSL) like C:/, D:/ mounted under /mnt/<letter>
  local letter m line use level
  for letter in {c..z}; do
    m="/mnt/${letter}"
    if [[ -d "$m" ]] && { command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$m" 2>/dev/null || grep -qs " $m " /proc/mounts; }; then
      line=$(df -P -h "$m" 2>/dev/null | awk 'NR==2 {print}')
      if [[ -n "$line" ]]; then
        use=$(echo "$line" | grep -oE '[0-9]+%' | tail -n1 | tr -d '%')
        [[ -z "$use" ]] && use=0
        level=OK
        if [[ -n "${DISK_CRITICAL_THRESHOLD:-}" && $use -ge $DISK_CRITICAL_THRESHOLD ]]; then level=CRITICAL; fi
        if [[ -n "${DISK_WARNING_THRESHOLD:-}" && $use -ge $DISK_WARNING_THRESHOLD && $level == OK ]]; then level=WARNING; fi
        echo "Windows ${letter^^}:/ on $m: ${use}% (${level})"
        if [[ "$level" == CRITICAL ]]; then status=2; fi
        if [[ "$level" == WARNING && $status -eq 0 ]]; then status=1; fi
      fi
    fi
  done
  return $status
}

# Retourne le load average (1 minute) et le nombre total de processus
monitor_system_load() {
  local load procs
  load=$(awk '{printf "%s", $1}' /proc/loadavg 2>/dev/null || echo 0)
  procs=$(ps -e --no-headers | wc -l 2>/dev/null || echo 0)
  echo "${load} (procs: ${procs})"
}

# Exécution système consolidée
run_system_monitoring() {
  echo "=== Système ==="
  monitor_cpu_usage || true
  monitor_memory_usage || true
  monitor_disk_space || true
  monitor_system_load || true
}

