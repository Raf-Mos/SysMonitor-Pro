#!/bin/bash
set -euo pipefail

# Fonctions à implémenter dans lib/process_manager.sh
# list_top_processes()        # Top 10 processus consommateurs
# find_zombie_processes()     # Détection processus zombies
# monitor_specific_process()  # Surveillance processus critique
# kill_problematic_process()  # Arrêt sécurisé de processus

list_top_processes() {
  echo "Top 10 des processus consommateurs de ressources :"
  ps aux --sort=-%cpu | head -n 11
  echo
}

find_zombie_processes() {
  echo "Processus zombies détectés :"
  local zombies
  zombies=$(ps aux | awk '{ if ($8 == "Z") print $0 }')
    if [[ -z "$zombies" ]]; then
        echo "Aucun processus zombie trouvé."
    else
        echo "$zombies"
    fi
  echo
}

# monitor_specific_process() {
#   local process_name="$1"
#   echo "Surveillance du processus '${process_name}' :"
#   ps -C "${process_name}" -o %cpu,%mem,cmd
#   echo
# }

monitor_specific_process() {
  local target="$1"
  
  # Check if input is a PID (numeric) or process name
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    echo "Surveillance du processus avec PID ${target} :"
    if ps -p "${target}" > /dev/null 2>&1; then
      ps -p "${target}" -o pid,%cpu,%mem,vsz,rss,tty,stat,start,time,cmd --no-headers
    else
      echo "Processus avec PID ${target} introuvable."
    fi
  else
    echo "Surveillance du processus '${target}' :"
    local pids
    pids=$(pgrep -f "$target" 2>/dev/null || true)
    
    if [[ -z "$pids" ]]; then
      echo "Aucun processus trouvé pour '${target}'."
    else
      echo "PIDs trouvés: $pids"
      ps -p "$pids" -o pid,%cpu,%mem,vsz,rss,tty,stat,start,time,cmd 2>/dev/null || echo "Erreur lors de l'affichage des détails."
    fi
  fi
  echo
}

kill_problematic_process() {
  local process_name="$1"
  echo "Tentative d'arrêt du processus ${process_name}..."
  pkill -f "${process_name}" && echo "Processus ${process_name} arrêté." || echo "Échec de l'arrêt du processus ${process_name}."
  echo
}

run_process_manager() {
  list_top_processes
  find_zombie_processes

    # Exemple de surveillance d'un processus critique par PID ou nom
    monitor_specific_process '252'  # Exemple avec un PID
    monitor_specific_process 'mysqld' # Exemple avec un nom de processus
    monitor_specific_process '5555'  # Exemple avec un PID inexistant
    monitor_specific_process 'process_inexistant' # Exemple avec un nom de processus inexistant
    kill_problematic_process 
}

echo "Gestionnaire de processus lancé."
echo "$(run_process_manager)"
$@