#!/usr/bin/env bash

PKG_MANAGER=""
AUR_HELPER=""

detect_package_manager() {
    case "$DISTRO" in
        arch|endeavouros)
            PKG_MANAGER="pacman"
            if command -v yay &>/dev/null; then
                AUR_HELPER="yay"
            elif command -v paru &>/dev/null; then
                AUR_HELPER="paru"
            else
                AUR_HELPER=""
            fi
            ;;
        ubuntu|debian)
            PKG_MANAGER="apt"
            ;;
        fedora)
            PKG_MANAGER="dnf"
            ;;
        opensuse)
            PKG_MANAGER="zypper"
            ;;
        *)
            PKG_MANAGER="unknown"
            ;;
    esac
    log_info "Package manager: ${PKG_MANAGER}"
}

pkg_update() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would update package database"
        return 0
    fi
    log_info "Updating package database..."
    case "$PKG_MANAGER" in
        pacman)
            sudo pacman -Sy --noconfirm
            ;;
        apt)
            sudo apt update
            ;;
        dnf)
            sudo dnf check-update || true
            ;;
        zypper)
            sudo zypper refresh
            ;;
    esac
    log_success "Package database updated"
}

pkg_install() {
    local pkg="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install: $pkg"
        STATS_PACKAGES=$((STATS_PACKAGES + 1))
        return 0
    fi
    if is_package_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        STATS_PACKAGES=$((STATS_PACKAGES + 1))
        return 0
    fi
    log_info "Installing: $pkg..."
    case "$PKG_MANAGER" in
        pacman)
            sudo pacman -S --needed --noconfirm "$pkg" &>/dev/null
            ;;
        apt)
            sudo apt install -y "$pkg" &>/dev/null
            ;;
        dnf)
            sudo dnf install -y "$pkg" &>/dev/null
            ;;
        zypper)
            sudo zypper install -y "$pkg" &>/dev/null
            ;;
    esac
    if is_package_installed "$pkg" 2>/dev/null || command -v "$pkg" &>/dev/null; then
        log_success "Installed: $pkg"
        STATS_PACKAGES=$((STATS_PACKAGES + 1))
    else
        log_warn "Package may not be fully installed: $pkg"
        STATS_PACKAGES=$((STATS_PACKAGES + 1))
    fi
}

pkg_install_list() {
    local list=("$@")
    for pkg in "${list[@]}"; do
        pkg_install "$pkg"
    done
}

pkg_install_from_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "Package list not found: $file"
        return 1
    fi
    local packages=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line// /}"
        [[ -z "$line" ]] && continue
        packages+=("$line")
    done <"$file"
    pkg_install_list "${packages[@]}"
}

pkg_install_aur() {
    local pkg="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install AUR package: $pkg"
        STATS_PACKAGES=$((STATS_PACKAGES + 1))
        return 0
    fi
    if ! command -v "${AUR_HELPER:-yay}" &>/dev/null; then
        log_warn "AUR helper not found. Installing yay..."
        _install_yay
    fi
    if is_package_installed "$pkg"; then
        log_debug "Already installed: $pkg"
        STATS_PACKAGES=$((STATS_PACKAGES + 1))
        return 0
    fi
    log_info "Installing AUR package: $pkg..."
    if ! "${AUR_HELPER:-yay}" -S --needed --noconfirm "$pkg" &>/dev/null; then
        log_error "Failed to install AUR package: $pkg"
        STATS_ERRORS=$((STATS_ERRORS + 1))
        return 1
    fi
    log_success "Installed AUR: $pkg"
    STATS_PACKAGES=$((STATS_PACKAGES + 1))
}

_install_yay() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install yay AUR helper"
        return 0
    fi
    if [[ "$DISTRO" != "arch" ]]; then
        log_error "AUR is only available on Arch Linux"
        return 1
    fi
    if ! command -v git &>/dev/null; then
        pkg_install git
    fi
    if ! command -v base-devel &>/dev/null; then
        sudo pacman -S --needed --noconfirm base-devel &>/dev/null
    fi
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone --depth=1 https://aur.archlinux.org/yay.git "$tmpdir/yay" &>/dev/null
    (cd "$tmpdir/yay" && makepkg -si --noconfirm) &>/dev/null
    rm -rf "$tmpdir"
    AUR_HELPER="yay"
    log_success "Installed yay AUR helper"
}

pkg_install_flatpak() {
    local app="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Flatpak: $app"
        return 0
    fi
    if ! command -v flatpak &>/dev/null; then
        pkg_install flatpak
    fi
    if flatpak list --app | grep -qi "$app"; then
        log_debug "Flatpak already installed: $app"
        return 0
    fi
    log_info "Installing Flatpak: $app..."
    flatpak install -y flathub "$app" &>/dev/null
    log_success "Installed Flatpak: $app"
}

pkg_install_cargo() {
    local crate="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install cargo crate: $crate"
        return 0
    fi
    if ! command -v cargo &>/dev/null; then
        log_warn "Cargo not available, skipping: $crate"
        return 1
    fi
    if command -v "$crate" &>/dev/null; then
        log_debug "Already installed: $crate"
        return 0
    fi
    log_info "Installing cargo crate: $crate..."
    cargo install "$crate" &>/dev/null
    log_success "Installed cargo: $crate"
}

pkg_install_pip() {
    local pkg="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install pip package: $pkg"
        return 0
    fi
    if ! command -v pip3 &>/dev/null; then
        log_warn "pip3 not available, skipping: $pkg"
        return 1
    fi
    log_info "Installing pip package: $pkg..."
    pip3 install --user "$pkg" &>/dev/null
    log_success "Installed pip: $pkg"
}

pkg_install_go() {
    local pkg="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Go package: $pkg"
        return 0
    fi
    if ! command -v go &>/dev/null; then
        log_warn "Go not available, skipping: $pkg"
        return 1
    fi
    log_info "Installing Go package: $pkg..."
    go install "${pkg}@latest" &>/dev/null
    log_success "Installed go: $pkg"
}

pkg_install_pipx() {
    local pkg="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install pipx package: $pkg"
        return 0
    fi
    if ! command -v pipx &>/dev/null; then
        if command -v pip3 &>/dev/null; then
            pip3 install --user pipx &>/dev/null
        else
            pkg_install pipx
        fi
    fi
    if command -v "$pkg" &>/dev/null; then
        log_debug "Already installed: $pkg"
        return 0
    fi
    log_info "Installing pipx package: $pkg..."
    pipx install "$pkg" &>/dev/null
    log_success "Installed pipx: $pkg"
}
