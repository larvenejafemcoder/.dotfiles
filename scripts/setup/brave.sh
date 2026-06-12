#!/usr/bin/env bash

setup_brave() {
    draw_section "BRAVE BROWSER"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Brave Browser"
        return 0
    fi

    if command -v brave-browser &>/dev/null || command -v brave &>/dev/null; then
        log_info "Brave Browser already installed"
        return 0
    fi

    if flatpak list --app 2>/dev/null | grep -qi "brave"; then
        log_info "Brave Browser already installed via Flatpak"
        return 0
    fi

    case "$DISTRO" in
        arch)
            if command -v yay &>/dev/null || command -v paru &>/dev/null; then
                pkg_install_aur brave-bin
            else
                log_info "Installing Brave via official script..."
                curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo gpg --dearmor -o /usr/share/keyrings/brave-browser.gpg 2>/dev/null || true
                echo "deb [signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser.list >/dev/null 2>/dev/null || {
                    pkg_install_flatpak com.brave.Browser
                    return 0
                }
                sudo apt update && sudo apt install -y brave-browser
            fi
            ;;
        ubuntu|debian)
            log_info "Adding Brave repository..."
            curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo gpg --dearmor -o /usr/share/keyrings/brave-browser.gpg 2>/dev/null || true
            echo "deb [signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser.list >/dev/null
            sudo apt update &>/dev/null
            sudo apt install -y brave-browser &>/dev/null
            ;;
        fedora)
            log_info "Adding Brave repository..."
            sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo &>/dev/null || {
                pkg_install_flatpak com.brave.Browser
                return 0
            }
            sudo dnf install -y brave-browser &>/dev/null
            ;;
        opensuse)
            pkg_install_flatpak com.brave.Browser
            return 0
            ;;
    esac

    if command -v brave-browser &>/dev/null || command -v brave &>/dev/null; then
        log_success "Brave Browser installed"
    else
        log_warn "Brave Browser may not be installed, trying Flatpak..."
        pkg_install_flatpak com.brave.Browser
    fi
}
