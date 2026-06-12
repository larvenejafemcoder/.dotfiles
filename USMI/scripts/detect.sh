#!/usr/bin/env bash
# ── USMI Phase 1: Core Loader ──
# Distro, hardware, and environment detection

DISTRO=""
DISTRO_ID=""
DISTRO_VERSION=""
DISTRO_ID_LIKE=""
ARCH=""
HOSTNAME=""
CPU=""
MEMORY=""
GPU=""
DESKTOP=""
SHELL=""
PKG_MANAGER=""
PKG_QUERY=""
PKG_INSTALL=""
PKG_UPDATE=""
PKG_LIST=""
AUR_HELPER=""

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        DISTRO_VERSION="$VERSION_ID"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
    fi

    if [[ -z "$DISTRO" ]]; then
        if command -v pacman &>/dev/null; then DISTRO="arch"
        elif command -v apt &>/dev/null; then
            [[ -f /etc/debian_version ]] && DISTRO="debian" || DISTRO="ubuntu"
        elif command -v dnf &>/dev/null; then DISTRO="fedora"
        elif command -v zypper &>/dev/null; then DISTRO="opensuse"
        else DISTRO="unknown"
        fi
    fi

    DISTRO="${DISTRO,,}"
    case "$DISTRO" in
        *endeavour*|*arch*|*cachy*) DISTRO="arch" ;;
        *ubuntu*|*mint*|*pop*|*kubuntu*) DISTRO="ubuntu" ;;
        *debian*) DISTRO="debian" ;;
        *fedora*|*nobara*) DISTRO="fedora" ;;
        *suse*|*opensuse*) DISTRO="opensuse" ;;
    esac
}

detect_package_manager() {
    case "$DISTRO" in
        arch)
            PKG_MANAGER="pacman"
            PKG_QUERY="pacman -Qi"
            PKG_INSTALL="sudo pacman -S --needed --noconfirm"
            PKG_UPDATE="sudo pacman -Sy --noconfirm"
            PKG_LIST="sudo pacman -S --needed --noconfirm"
            if command -v yay &>/dev/null; then AUR_HELPER="yay"
            elif command -v paru &>/dev/null; then AUR_HELPER="paru"
            fi
            ;;
        ubuntu|debian)
            PKG_MANAGER="apt"
            PKG_QUERY="dpkg -s"
            PKG_INSTALL="sudo apt install -y"
            PKG_UPDATE="sudo apt update"
            PKG_LIST="sudo apt install -y"
            ;;
        fedora)
            PKG_MANAGER="dnf"
            PKG_QUERY="rpm -q"
            PKG_INSTALL="sudo dnf install -y"
            PKG_UPDATE="sudo dnf check-update || true"
            PKG_LIST="sudo dnf install -y"
            ;;
        opensuse)
            PKG_MANAGER="zypper"
            PKG_QUERY="rpm -q"
            PKG_INSTALL="sudo zypper install -y"
            PKG_UPDATE="sudo zypper refresh"
            PKG_LIST="sudo zypper install -y"
            ;;
    esac
}

detect_hardware() {
    ARCH="$(uname -m)"
    HOSTNAME="$(hostname)"

    if [[ -f /proc/cpuinfo ]]; then
        CPU="$(grep -m1 'model name' /proc/cpuinfo | sed 's/.*:\s*//' | head -c60)"
    fi

    if [[ -f /proc/meminfo ]]; then
        local mem_kb
        mem_kb="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
        MEMORY="$(echo "scale=1; $mem_kb / 1024 / 1024" | bc)GB" 2>/dev/null || \
        MEMORY="$((mem_kb / 1024 / 1024))GB"
    fi

    if command -v lspci &>/dev/null; then
        GPU="$(lspci | grep -i 'vga\|3d\|display' | sed 's/.*:\s*//' | head -1 | head -c60)"
    elif command -v glxinfo &>/dev/null; then
        GPU="$(glxinfo | grep 'OpenGL renderer' | sed 's/.*:\s*//' | head -c60)"
    fi

    DESKTOP="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
    SHELL="$(basename "${SHELL:-unknown}")"
}

detect_existing_tools() {
    local tools=("git" "gcc" "python3" "node" "rustc" "go" "docker" "nvim" "tmux" "zsh" "ollama")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            declare -g "HAS_${tool^^}=true"
        else
            declare -g "HAS_${tool^^}=false"
        fi
    done
}

detect_all() {
    detect_distro
    detect_package_manager
    detect_hardware
    detect_existing_tools
}

print_system_info() {
    echo "========================================"
    echo " USMI SYSTEM LOADER"
    echo "========================================"
    printf " %-8s : %s\n" "OS" "${DISTRO^} ${DISTRO_VERSION}"
    printf " %-8s : %s\n" "Kernel" "$(uname -r)"
    printf " %-8s : %s\n" "Arch" "$ARCH"
    printf " %-8s : %s\n" "CPU" "${CPU:-Unknown}"
    printf " %-8s : %s\n" "GPU" "${GPU:-Unknown}"
    printf " %-8s : %s\n" "RAM" "${MEMORY:-Unknown}"
    printf " %-8s : %s\n" "DE" "$DESKTOP"
    printf " %-8s : %s\n" "Shell" "$SHELL"
    printf " %-8s : %s\n" "PM" "$PKG_MANAGER"
    echo "----------------------------------------"
}

detect_all
