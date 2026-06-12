#!/usr/bin/env bash
# ── USMI Common Library ──
# Colors, logging, and utility functions

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RED_BOLD='\033[1;31m'
GREEN_BOLD='\033[1;32m'
YELLOW_BOLD='\033[1;33m'
BLUE_BOLD='\033[1;34m'
MAGENTA_BOLD='\033[1;35m'
CYAN_BOLD='\033[1;36m'

log_info()    { echo -e "${CYAN}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $1" >&2; }
log_step()    { echo -e "\n  ${BLUE_BOLD}[$1/$2]${RESET} ${BOLD}$3${RESET}"; echo -e "  ${DIM}──────────────────────────────────────────${RESET}"; }
log_debug()   { [[ "${DEBUG:-false}" == "true" ]] && echo -e "${DIM}[DEBUG]${RESET} $1"; }

draw_separator() {
    echo -e "${DIM}────────────────────────────────────────────${RESET}"
}

draw_header() {
    echo -e "${CYAN_BOLD}"
    echo "╔══════════════════════════════════════╗"
    echo "║     USMI SYSTEM DEPLOYMENT ENGINE     ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${RESET}"
}

draw_section() {
    echo
    echo -e "${BLUE_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN_BOLD}  ◆ $1${RESET}"
    echo -e "${BLUE_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

confirm() {
    local prompt="${1:-Proceed?}"
    local yn
    read -rp "$prompt [y/N]: " yn
    [[ "$yn" =~ ^[Yy] ]] && return 0 || return 1
}

is_installed() {
    command -v "$1" &>/dev/null
}

is_package_installed() {
    local pkg="$1"
    case "$DISTRO" in
        arch) pacman -Qi "$pkg" &>/dev/null ;;
        ubuntu|debian) dpkg -s "$pkg" &>/dev/null 2>&1 ;;
        fedora|opensuse) rpm -q "$pkg" &>/dev/null ;;
        *) return 1 ;;
    esac
}
