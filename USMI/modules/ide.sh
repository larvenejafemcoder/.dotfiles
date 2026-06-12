#!/usr/bin/env bash
# ── USMI Phase 8: IDE Installer Module ──

install_vscode() {
    if is_installed code; then
        log_success "VSCode already installed"
        return 0
    fi
    log_info "Installing VSCode..."
    case "$DISTRO" in
        arch)
            if [[ -n "$AUR_HELPER" ]]; then
                $AUR_HELPER -S --needed --noconfirm visual-studio-code-bin 2>/dev/null || return 1
            else
                install_aur visual-studio-code-bin
            fi
            ;;
        ubuntu|debian)
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg 2>/dev/null
            echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
            sudo apt update && sudo apt install -y code 2>/dev/null || return 1
            ;;
        fedora)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null
            echo "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
            sudo dnf install -y code 2>/dev/null || return 1
            ;;
        opensuse)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null
            echo "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/zypp/repos.d/vscode.repo >/dev/null
            sudo zypper refresh && sudo zypper install -y code 2>/dev/null || return 1
            ;;
    esac
    log_success "VSCode installed"
}

install_cursor() {
    if is_installed cursor; then
        log_success "Cursor already installed"
        return 0
    fi
    log_info "Installing Cursor..."
    if [[ "$DISTRO" == "arch" ]] && [[ -n "$AUR_HELPER" ]]; then
        $AUR_HELPER -S --needed --noconfirm cursor-bin 2>/dev/null || {
            log_warn "Download Cursor from: https://cursor.sh"
            return 1
        }
    else
        log_warn "Download Cursor from: https://cursor.sh"
        return 1
    fi
    log_success "Cursor installed"
}

install_zed() {
    if is_installed zed; then
        log_success "Zed already installed"
        return 0
    fi
    log_info "Installing Zed..."
    curl -fsSL https://zed.dev/install.sh | sh 2>/dev/null || {
        log_warn "Zed install failed"
        return 1
    }
    log_success "Zed installed"
}

install_neovim() {
    if is_installed nvim; then
        log_success "Neovim already installed"
        return 0
    fi
    log_info "Installing Neovim..."
    case "$DISTRO" in
        arch)   sudo pacman -S --needed --noconfirm neovim 2>/dev/null || return 1 ;;
        ubuntu|debian) sudo apt install -y neovim 2>/dev/null || return 1 ;;
        fedora) sudo dnf install -y neovim 2>/dev/null || return 1 ;;
        opensuse) sudo zypper install -y neovim 2>/dev/null || return 1 ;;
    esac
    log_success "Neovim installed"
}

install_jetbrains() {
    log_info "JetBrains Toolbox installs all IDEs"
    if is_installed jetbrains-toolbox; then
        log_success "JetBrains Toolbox already installed"
        return 0
    fi
    if [[ "$DISTRO" == "arch" ]] && [[ -n "$AUR_HELPER" ]]; then
        $AUR_HELPER -S --needed --noconfirm jetbrains-toolbox 2>/dev/null || {
            log_warn "Download from: https://www.jetbrains.com/toolbox-app/"
            return 1
        }
    else
        log_warn "Download JetBrains Toolbox from: https://www.jetbrains.com/toolbox-app/"
        return 1
    fi
    log_success "JetBrains Toolbox installed"
}

ide_menu() {
    draw_section "IDE INSTALLER"
    echo "  [1] VS Code"
    echo "  [2] Cursor"
    echo "  [3] Zed"
    echo "  [4] Neovim"
    echo "  [5] JetBrains Suite"
    echo "  [6] Everything"
    echo "  [0] Skip"
    echo
    read -rp "  Select IDE: " ide_choice

    case "$ide_choice" in
        1) install_vscode ;;
        2) install_cursor ;;
        3) install_zed ;;
        4) install_neovim ;;
        5) install_jetbrains ;;
        6)
            install_vscode
            install_cursor
            install_zed
            install_neovim
            install_jetbrains
            ;;
        *) log_info "IDE installation skipped" ;;
    esac
}
