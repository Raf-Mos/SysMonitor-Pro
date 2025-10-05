#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Convertir CRLF -> LF avant tout (compatibilité WSL)
fix_line_endings() {
    for f in \
        "$SCRIPT_DIR/config/settings.conf" \
        "$SCRIPT_DIR/config/thresholds.conf" \
        "$SCRIPT_DIR/lib/logger.sh" \
        "$SCRIPT_DIR/lib/system_monitor.sh" \
        "$SCRIPT_DIR/lib/process_manager.sh" \
        "$SCRIPT_DIR/lib/service_checker.sh" \
        "$SCRIPT_DIR/lib/network_utils.sh" \
        "$SCRIPT_DIR/main.sh"; do
        [ -f "$f" ] && sed -i 's/\r$//' "$f" 2>/dev/null || true
    done
}

fix_line_endings

# Configs (après normalisation des fins de ligne)
source "$SCRIPT_DIR/config/settings.conf"
source "$SCRIPT_DIR/config/thresholds.conf"

# Libs
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/system_monitor.sh"
source "$SCRIPT_DIR/lib/process_manager.sh"
source "$SCRIPT_DIR/lib/service_checker.sh"
source "$SCRIPT_DIR/lib/network_utils.sh"

VERSION="0.1.0"

show_help() {
    cat <<EOF
SysMonitor Pro v$VERSION (minimal)
Usage: $0 [--system-only|--process-only|--service-only|--network-only]
EOF
}

validate_prerequisites() {
    mkdir -p "$LOG_DIR" "$REPORT_DIR"
    return 0
}

generate_system_report() {
    local out="$REPORT_DIR/system_report_$(date +%Y%m%d).html"
        mkdir -p "$REPORT_DIR"

        # Small helpers
        html_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
        append_pre_section() {
                # $1=Title, $2=Content
                {
                        echo "<section>";
                        echo "  <h2>$1</h2>";
                        echo "  <pre>";
                        printf "%s" "${2:-}" | html_escape
                        echo "  </pre>";
                        echo "</section>";
                } >> "$out"
        }

        # Collect data from modules
        local cpu mem load disk_lines traffic
        cpu=$(monitor_cpu_usage 2>/dev/null || echo 0)
        mem=$(monitor_memory_usage 2>/dev/null || echo 0)
        load=$(monitor_system_load 2>/dev/null || echo 0)
        disk_lines=$(monitor_disk_space 2>/dev/null || true)

        local top_procs zombies
        top_procs=$(list_top_processes 2>/dev/null || true)
        zombies=$(find_zombie_processes 2>/dev/null || true)

        local services_status
        services_status=$(check_critical_services 2>/dev/null || true)

        local net_connect net_ifaces net_ports net_traffic
        net_connect=$(check_network_connectivity 2>/dev/null || true)
        net_ifaces=$(monitor_network_interfaces 2>/dev/null || true)
        net_ports=$(check_open_ports 2>/dev/null || true)
        net_traffic=$(monitor_network_traffic 2>/dev/null || true)

        local recent_logs=""
        if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
                recent_logs=$(tail -n 200 "$LOG_FILE" 2>/dev/null || true)
        fi

            # Determine classes for severity styling
            local cpuClass="success" memClass="success"
            [[ "$cpu" == *CRITICAL* ]] && cpuClass="critical" || true
            [[ "$cpu" == *WARNING* ]] && cpuClass="warning" || true
            # Extract memory percent and map to thresholds
            local memPct
            memPct=$(echo "$mem" | sed -n 's/.*RAM: \([0-9]\+\)%.*/\1/p')
            if [[ -n "${MEMORY_CRITICAL_THRESHOLD:-}" && -n "$memPct" && "$memPct" -ge "$MEMORY_CRITICAL_THRESHOLD" ]]; then
                    memClass="critical"
            elif [[ -n "${MEMORY_WARNING_THRESHOLD:-}" && -n "$memPct" && "$memPct" -ge "$MEMORY_WARNING_THRESHOLD" ]]; then
                    memClass="warning"
            else
                    memClass="success"
            fi

            # Write HTML
    cat > "$out" <<HTML
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>SysMonitor Pro</title>
        <style>
            body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;margin:20px;line-height:1.4}
            h1{margin-bottom:0.2rem}
            .meta{color:#555;margin-bottom:1rem}
            section{margin:1rem 0;padding:0.5rem 0;border-top:1px solid #eee}
            ul.kv{list-style:none;padding:0}
            ul.kv li{padding:2px 0}
            pre{background:#0b1021;color:#e6e6e6;padding:10px;border-radius:6px;overflow:auto}
            code{font-family:ui-monospace,SFMono-Regular,Consolas,Monaco,monospace}
            .small{font-size:0.9em;color:#666}
                .critical{background:#e74c3c;color:#fff;padding:2px 6px;border-radius:4px}
                .warning{background:#f39c12;color:#fff;padding:2px 6px;border-radius:4px}
                .success{background:#27ae60;color:#fff;padding:2px 6px;border-radius:4px}
                details{border:1px solid #eee;border-radius:6px;padding:0.6rem;background:#fafafa}
                details>summary{cursor:pointer;font-weight:600}
                .subsection{margin:0.5rem 0 0}
        </style>
    </head>
    <body>
        <h1>SysMonitor Pro - Rapport</h1>
            <div class="meta small">Généré le: $(date '+%Y-%m-%d %H:%M:%S') | Serveur: $(hostname)</div>
            <details open>
                <summary>Groupe: Système</summary>
                <div class="subsection">
                    <ul class="kv">
                        <li>CPU: <span class="${cpuClass}">${cpu}</span></li>
                        <li>État mémoire: <span class="${memClass}">${mem}</span></li>
                        <li>Load (1m): ${load}</li>
                    </ul>
                </div>
                <div class="subsection">
                    <h3>Disques (utilisation)</h3>
                    <pre>$(printf "%s" "${disk_lines:-Aucune donnée}")</pre>
                </div>
            </details>
HTML

    # Disks handled inside System group above

        # Processes group
        {
            echo "<details open>"; echo "<summary>Groupe: Processus</summary>";
            echo "<div class=\"subsection\">"; echo "<h3>Top (CPU)</h3>";
            echo "<pre>"; printf "%s" "${top_procs:-Aucune donnée}" | html_escape; echo "</pre>";
            echo "</div>";
            echo "<div class=\"subsection\">"; echo "<h3>Zombies</h3>";
            echo "<pre>"; printf "%s" "${zombies:-Aucun}" | html_escape; echo "</pre>";
            echo "</div>"; echo "</details>";
        } >> "$out"

        # Services group
        {
            echo "<details open>"; echo "<summary>Groupe: Services</summary>";
            echo "<div class=\"subsection\">"; echo "<h3>Services critiques</h3>";
            echo "<pre>"; printf "%s" "${services_status:-Aucune donnée}" | html_escape; echo "</pre>";
            echo "</div>"; echo "</details>";
        } >> "$out"

    # Network group
        {
            echo "<details open>"; echo "<summary>Groupe: Réseau</summary>";
            echo "<div class=\"subsection\">"; echo "<h3>Connectivité</h3>";
            echo "<pre>"; printf "%s" "${net_connect:-Aucune donnée}" | html_escape; echo "</pre>";
            echo "</div>";
            echo "<div class=\"subsection\">"; echo "<h3>Interfaces</h3>";
            echo "<pre>"; printf "%s" "${net_ifaces:-Aucune donnée}" | html_escape; echo "</pre>";
            echo "</div>";
            echo "<div class=\"subsection\">"; echo "<h3>Ports à l'écoute</h3>";
            echo "<pre>"; printf "%s" "${net_ports:-Aucune donnée}" | html_escape; echo "</pre>";
            echo "</div>";
            echo "<div class=\"subsection\">"; echo "<h3>Trafic (1s)</h3>";
            echo "<pre>"; printf "%s" "${net_traffic:-Aucune donnée}" | html_escape; echo "</pre>";
            echo "</div>"; echo "</details>";
        } >> "$out"
        # Logs (optional)
        if [[ -n "${recent_logs:-}" ]]; then
                append_pre_section "Logs récents" "${recent_logs}"
        fi

        # Close HTML
        {
            echo "  </body>";
            echo "</html>";
        } >> "$out"

        echo "Rapport: $out"
}

cleanup() {
    log_info "Nettoyage en cours..." || true
    [[ -n "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR" || true
}
trap cleanup EXIT INT TERM

main() {
    local sys=false proc=false svc=false net=false
    if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then show_help; exit 0; fi

    case "${1:-}" in
        --system-only) sys=true ;;
        --process-only) proc=true ;;
        --service-only) svc=true ;;
        --network-only) net=true ;;
    esac

    init_logger || true
    validate_prerequisites || exit 1

    # Simple input/threshold validation per README
    validate_input() {
        local input="$1"; local type="$2"
        case "$type" in
            threshold)
                [[ "$input" =~ ^[0-9]+$ ]] || return 1
                [[ "$input" -ge 0 && "$input" -le 100 ]] || return 1
                ;;
            service)
                if command -v systemctl >/dev/null 2>&1; then
                    systemctl list-unit-files | grep -q "^$input" || return 1
                else
                    pgrep -f "$input" >/dev/null 2>&1 || return 1
                fi
                ;;
        esac
        return 0
    }

    if $sys; then run_system_monitoring; exit $?; fi
    if $proc; then run_process_monitoring; exit $?; fi
    if $svc; then run_service_monitoring; exit $?; fi
    if $net; then run_network_monitoring; exit $?; fi

    # Par défaut: orchestrate all modules + report (per README)
    log_info "Début monitoring SysMonitor Pro"
    run_system_monitoring || true
    run_process_monitoring || true
    run_service_monitoring || true
    run_network_monitoring || true
    generate_system_report || true
    log_success "Monitoring terminé avec succès"
}

main "$@"