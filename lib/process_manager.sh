#!/bin/bash
set -euo pipefail

# Top 10 processus consommateurs (CPU)
list_top_processes() {
  # Print header and top 10 by CPU; use -%cpu for sort key compatibility
  if ps -eo user,pid,%cpu,%mem,vsz,rss,tty,stat,start,time,cmd --sort=-%cpu >/dev/null 2>&1; then
    ps -eo user,pid,%cpu,%mem,vsz,rss,tty,stat,start,time,cmd --sort=-%cpu | head -n 11
  else
    # Fallback: simpler format
    ps aux --sort=-%cpu | head -n 11
  fi
}

# Détection de zombies
find_zombie_processes() {
  ps -eo user,pid,stat,cmd | awk '$3 ~ /Z/ {print}' || true
}

# Surveillance d'un processus par nom (retourne lignes trouvées)
monitor_specific_process() {
  local name=${1:-sshd}
  pgrep -af "$name" || true
}

# Arrêt sécurisé: essaye SIGTERM, puis SIGKILL si nécessaire. Retourne 0 si succès
kill_problematic_process() {
  local pid=${1:-}
  local timeout=${2:-5}
  if [[ -z "$pid" ]]; then
    echo "kill_problematic_process: no pid provided" >&2
    return 2
  fi
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "PID $pid not running" >&2; return 3
  fi
  kill -TERM "$pid" 2>/dev/null || true
  local waited=0
  while kill -0 "$pid" 2>/dev/null; do
    sleep 1; waited=$((waited+1))
    if (( waited >= timeout )); then
      echo "PID $pid did not stop, sending SIGKILL" >&2
      kill -KILL "$pid" 2>/dev/null || true
      break
    fi
  done
  return 0
}

run_process_monitoring() {
  local target="${1:-}"
  echo "=== Processus: TOP ==="; list_top_processes
  echo "=== Processus: ZOMBIES ==="; find_zombie_processes || true
  if [[ -n "$target" ]]; then
    echo "=== Processus: ${target} ==="; monitor_specific_process "$target" || true
  fi
}

