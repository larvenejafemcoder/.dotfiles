#!/usr/bin/env bash

DISTRO=""
DISTRO_VERSION=""
DISTRO_ID_LIKE=""
ARCH=""
HOSTNAME=""
USERNAME=""
CPU=""
MEMORY=""
GPU=""
DESKTOP=""
SHELL=""

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        DISTRO_VERSION="$VERSION_ID"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
    fi

    if [[ -z "$DISTRO" ]]; then
        if command -v pacman &>/dev/null; then
            DISTRO="arch"
        elif command -v apt &>/dev/null; then
            if [[ -f /etc/debian_version ]]; then
                DISTRO="debian"
            else
                DISTRO="ubuntu"
            fi
        elif command -v dnf &>/dev/null; then
            DISTRO="fedora"
        elif command -v zypper &>/dev/null; then
            DISTRO="opensuse"
        else
            DISTRO="unknown"
        fi
    fi

    DISTRO="${DISTRO,,}"
    case "$DISTRO" in
        *endeavour*|*arch*) DISTRO="arch" ;;
        *ubuntu*) DISTRO="ubuntu" ;;
        *debian*) DISTRO="debian" ;;
        *fedora*) DISTRO="fedora" ;;
        *suse*|*opensuse*) DISTRO="opensuse" ;;
    esac
}

detect_hardware() {
    ARCH="$(uname -m)"
    HOSTNAME="$(hostname)"
    USERNAME="${USER:-$(whoami)}"

    if [[ -f /proc/cpuinfo ]]; then
        CPU="$(grep -m1 'model name' /proc/cpuinfo | sed 's/.*:\s*//' | head -c60)"
    fi

    if [[ -f /proc/meminfo ]]; then
        local mem_kb
        mem_kb="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
        MEMORY="$(echo "scale=1; $mem_kb / 1024 / 1024" | bc)GB"
    fi

    if command -v lspci &>/dev/null; then
        GPU="$(lspci | grep -i 'vga\|3d\|display' | sed 's/.*:\s*//' | head -1 | head -c60)"
    fi

    DESKTOP="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
    SHELL="$(basename "${SHELL:-unknown}")"
}

detect_environment() {
    detect_distro
    detect_hardware

    log_info "Detected distribution: ${DISTRO} ${DISTRO_VERSION}"
    log_info "Architecture: ${ARCH}"
    log_info "Kernel: $(uname -r)"
}

display_summary() {
    draw_section "SYSTEM OVERVIEW"
    draw_table_row "Distribution" "${DISTRO^} ${DISTRO_VERSION}"
    draw_table_row "Hostname" "$HOSTNAME"
    draw_table_row "Username" "$USERNAME"
    draw_table_row "Architecture" "$ARCH"
    draw_table_row "Kernel" "$(uname -r)"
    draw_table_row "CPU" "${CPU:-Unknown}"
    draw_table_row "Memory" "${MEMORY:-Unknown}"
    draw_table_row "GPU" "${GPU:-Unknown}"
    draw_table_row "Desktop" "$DESKTOP"
    draw_table_row "Shell" "$SHELL"
    echo
}
