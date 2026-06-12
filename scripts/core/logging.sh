#!/usr/bin/env bash

LOG_FILE="${LOG_FILE:-$HOME/.local/share/dotfiles/install.log}"
export LOG_FILE

init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    : >"$LOG_FILE"
    log_info "Dotfiles deployment started at $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Distribution: ${DISTRO:-unknown}"
    log_info "Hostname: $(hostname)"
}

log_info() {
    local msg="$1"
    echo -e "${CYAN}[INFO]${RESET} $msg"
    echo "[INFO] $(date '+%H:%M:%S') $msg" >>"$LOG_FILE"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[OK]${RESET} $msg"
    echo "[OK]   $(date '+%H:%M:%S') $msg" >>"$LOG_FILE"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${RESET} $msg"
    echo "[WARN] $(date '+%H:%M:%S') $msg" >>"$LOG_FILE"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${RESET} $msg" >&2
    echo "[ERROR] $(date '+%H:%M:%S') $msg" >>"$LOG_FILE"
}

log_debug() {
    local msg="$1"
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${DIM}[DEBUG]${RESET} $msg"
    fi
    echo "[DEBUG] $(date '+%H:%M:%S') $msg" >>"$LOG_FILE"
}

log_section() {
    local msg="$1"
    echo "" >>"$LOG_FILE"
    echo "═════════════════════════════════════════" >>"$LOG_FILE"
    echo "$msg" >>"$LOG_FILE"
    echo "═════════════════════════════════════════" >>"$LOG_FILE"
}
