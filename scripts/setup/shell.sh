#!/usr/bin/env bash

setup_zsh() {
    draw_section "SHELL SETUP"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would set up Zsh with Oh My Zsh"
        return 0
    fi

    if [[ "$SHELL" != *"zsh"* ]] || [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        log_info "Setting up Zsh..."

        if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
            log_info "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &>/dev/null || true

            log_info "Installing Powerlevel10k theme..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" 2>/dev/null || true

            log_info "Installing plugins..."
            git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" 2>/dev/null || true
            git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" 2>/dev/null || true
            git clone --depth=1 https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" 2>/dev/null || true

            log_success "Oh My Zsh installed"
        else
            log_info "Oh My Zsh already present"
        fi

        if [[ "$SHELL" != *"zsh"* ]] && [[ "$UNATTENDED" == "true" ]]; then
            log_info "Changing default shell to Zsh..."
            chsh -s "$(which zsh)" 2>/dev/null || log_warn "Could not change shell. Run: chsh -s $(which zsh)"
        fi
    else
        log_info "Zsh already configured"
    fi

    if [[ ! -d "$HOME/.config/zsh" ]]; then
        mkdir -p "$HOME/.config/zsh"
    fi
    log_success "Shell setup complete"
}

setup_starship() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Starship prompt"
        return 0
    fi

    if command -v starship &>/dev/null; then
        log_info "Starship already installed"
        return 0
    fi

    log_info "Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y &>/dev/null || {
        log_warn "Starship install script failed, trying package manager..."
        pkg_install starship
    }

    if command -v starship &>/dev/null; then
        log_success "Starship installed"
    else
        log_error "Starship installation failed"
        return 1
    fi
}

setup_fish() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would configure Fish shell"
        return 0
    fi

    if ! command -v fish &>/dev/null; then
        log_info "Fish not installed, skipping Fish setup"
        return 0
    fi

    if [[ ! -d "$HOME/.local/share/omf" ]]; then
        log_info "Installing Oh My Fish..."
        curl -fsSL https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish &>/dev/null || true
    fi

    log_success "Fish shell configured"
}

setup_shell() {
    setup_zsh
    setup_starship
    setup_fish
}
