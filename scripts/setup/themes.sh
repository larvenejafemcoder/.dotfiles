#!/usr/bin/env bash

setup_catppuccin() {
    draw_section "CATPPUCCIN THEME"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Catppuccin theme"
        return 0
    fi

    if command -v gsettings &>/dev/null; then
        log_info "Applying Catppuccin Mocha GTK theme..."

        local theme_dir="${HOME}/.local/share/themes"
        local icon_dir="${HOME}/.local/share/icons"
        mkdir -p "$theme_dir" "$icon_dir"

        if [[ ! -d "${theme_dir}/Catppuccin-Mocha" ]]; then
            log_info "Downloading Catppuccin GTK theme..."
            local tmpdir
            tmpdir="$(mktemp -d)"
            curl -fsSL "https://github.com/catppuccin/gtk/releases/latest/download/Catppuccin-Mocha.zip" -o "$tmpdir/Catppuccin-Mocha.zip" &>/dev/null || {
                log_warn "Could not download Catppuccin GTK theme"
                rm -rf "$tmpdir"
                return 0
            }
            unzip -q "$tmpdir/Catppuccin-Mocha.zip" -d "$theme_dir" 2>/dev/null || true
            rm -rf "$tmpdir"
            log_success "Catppuccin GTK theme downloaded"
        fi

        if [[ ! -d "${icon_dir}/catppuccin-mocha" ]]; then
            log_info "Downloading Catppuccin icons..."
            local tmpdir
            tmpdir="$(mktemp -d)"
            curl -fsSL "https://github.com/catppuccin/icons/releases/latest/download/Catppuccin-Mocha.zip" -o "$tmpdir/icons.zip" &>/dev/null || {
                log_warn "Could not download Catppuccin icons"
                rm -rf "$tmpdir"
                return 0
            }
            unzip -q "$tmpdir/icons.zip" -d "$icon_dir" 2>/dev/null || true
            rm -rf "$tmpdir"
            log_success "Catppuccin icons downloaded"
        fi
    else
        log_info "gsettings not available, skipping GTK theme config"
    fi

    log_success "Catppuccin theme prepared"
}

setup_gnome_themes() {
    draw_section "GNOME THEMES"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install GNOME themes"
        return 0
    fi

    if [[ -d "${DOTFILES_DIR}/themes/tahoe-theme" ]] && [[ -f "${DOTFILES_DIR}/themes/tahoe-theme/install.sh" ]]; then
        log_info "Installing Tahoe theme..."
        bash "${DOTFILES_DIR}/themes/tahoe-theme/install.sh" -d &>/dev/null || {
            log_warn "Tahoe theme install encountered warnings"
        }
        log_success "Tahoe theme installed"
    fi

    if [[ -d "${DOTFILES_DIR}/themes/whitesur-All" ]] && [[ -f "${DOTFILES_DIR}/themes/whitesur-All/install.sh" ]]; then
        log_info "Installing WhiteSur theme..."
        bash "${DOTFILES_DIR}/themes/whitesur-All/install.sh" &>/dev/null || {
            log_warn "WhiteSur theme install encountered warnings"
        }
        log_success "WhiteSur theme installed"
    fi
}

setup_themes() {
    setup_catppuccin
    setup_gnome_themes
}
