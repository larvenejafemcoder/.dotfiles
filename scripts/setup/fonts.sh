#!/usr/bin/env bash

setup_fonts() {
    draw_section "FONT INSTALLATION"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install fonts"
        return 0
    fi

    local font_dir="${HOME}/.local/share/fonts"
    mkdir -p "$font_dir"

    if fc-list | grep -qi "Meslo.*Nerd" &>/dev/null; then
        log_info "Meslo Nerd Font already installed"
    else
        log_info "Downloading Meslo Nerd Font..."
        local tmpdir
        tmpdir="$(mktemp -d)"
        curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" -o "$tmpdir/Meslo.zip" &>/dev/null

        if [[ -f "$tmpdir/Meslo.zip" ]]; then
            unzip -q "$tmpdir/Meslo.zip" -d "$tmpdir/Meslo" 2>/dev/null
            find "$tmpdir/Meslo" -name "*.ttf" -exec cp {} "$font_dir/" \; 2>/dev/null
            log_success "Meslo Nerd Font installed"
        else
            log_warn "Failed to download Meslo Nerd Font"
        fi
        rm -rf "$tmpdir"
    fi

    if [[ -d "${DOTFILES_DIR}/fonts/Meslo" ]]; then
        log_info "Installing local Meslo font files..."
        find "${DOTFILES_DIR}/fonts/Meslo" -name "*.ttf" -exec cp {} "$font_dir/" \; 2>/dev/null
        log_success "Local Meslo fonts installed"
    fi

    if fc-list | grep -qi "JetBrains.*Mono" &>/dev/null; then
        log_info "JetBrains Mono already installed"
    else
        log_info "Installing JetBrains Mono..."
        local tmpdir
        tmpdir="$(mktemp -d)"
        curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$tmpdir/JetBrainsMono.zip" &>/dev/null

        if [[ -f "$tmpdir/JetBrainsMono.zip" ]]; then
            unzip -q "$tmpdir/JetBrainsMono.zip" -d "$tmpdir/JetBrainsMono" 2>/dev/null
            find "$tmpdir/JetBrainsMono" -name "*.ttf" -exec cp {} "$font_dir/" \; 2>/dev/null
            log_success "JetBrains Mono installed"
        fi
        rm -rf "$tmpdir"
    fi

    log_info "Updating font cache..."
    fc-cache -f "$font_dir" &>/dev/null
    log_success "Font cache updated"
}
