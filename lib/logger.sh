#!/bin/bash
set -euo pipefail

LOG_DIR=${LOG_DIR:-./logs}
LOG_FILE="$LOG_DIR/sysmonitor.log"

init_logger() {
	mkdir -p "$LOG_DIR"
}

log_with_level() {
	local level="$1"; shift
	local message="$*"
	local timestamp
	timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	mkdir -p "$LOG_DIR"
	# Format: [TIMESTAMP] [LEVEL] MESSAGE
	echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE" >/dev/null

	# Syslog for critical errors (per README), if logger exists
	if [[ "$level" == "CRITICAL" ]] && command -v logger >/dev/null 2>&1; then
		logger -p local0.err "SysMonitor: $message" || true
	fi
}

log_info()    { log_with_level INFO "$*"; }
log_warning() { log_with_level WARNING "$*"; }
log_error()   { log_with_level ERROR "$*"; }
log_success() { log_with_level SUCCESS "$*"; }
log_critical(){ log_with_level CRITICAL "$*"; }

rotate_logs() { :; }
cleanup_old_logs() { :; }
