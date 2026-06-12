#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

DISTRO=""

detect_distro() {
    if command -v pacman &>/dev/null; then
        DISTRO="arch"
    elif command -v apt &>/dev/null; then
        DISTRO="debian"
    elif command -v dnf &>/dev/null; then
        DISTRO="fedora"
    elif command -v zypper &>/dev/null; then
        DISTRO="suse"
    else
        DISTRO="unknown"
    fi
    info "Detected distribution: $DISTRO"
}

install_packages() {
    detect_distro

    case "$DISTRO" in
        arch)
            info "Updating Arch system..."
            sudo pacman -Syu --noconfirm
            info "Installing Arch packages..."
            sudo pacman -S --needed --noconfirm \
                alacritty \
                zsh \
                curl \
                fish \
                kitty \
                stow \
                dconf \
                git \
                unzip
            ;;
        debian)
            info "Updating Debian system..."
            sudo apt update
            info "Installing Debian packages..."
            local deb_pkgs=(
                zsh
                curl
                git
                stow
                dconf-cli
                unzip
                fish
            )
            # kitty is available in Debian bookworm+
            if apt-cache show kitty &>/dev/null 2>&1; then
                deb_pkgs+=(kitty)
            else
                warn "kitty not in repos, skipping. Install manually from https://sw.kovidgoyal.net/kitty/"
            fi
            sudo apt install -y "${deb_pkgs[@]}"
            # Alacritty may not be in Debian repos
            if ! command -v alacritty &>/dev/null; then
                warn "alacritty not found. Install via cargo or from https://alacritty.org/"
            fi
            # Skip dankmaterialshell on Debian
            info "Debian setup complete (dankmaterialshell excluded)"
            ;;
        fedora)
            info "Installing Fedora packages..."
            sudo dnf install -y \
                alacritty \
                zsh \
                curl \
                fish \
                kitty \
                stow \
                dconf \
                git \
                unzip
            ;;
        suse)
            info "Installing openSUSE packages..."
            sudo zypper install -y \
                alacritty \
                zsh \
                curl \
                fish \
                kitty \
                stow \
                dconf \
                git \
                unzip
            ;;
        *)
            error "Unsupported distribution. Install packages manually."
            exit 1
            ;;
    esac

    ok "System packages installed successfully"
}
