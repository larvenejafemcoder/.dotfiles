#!/usr/bin/env bash

setup_git() {
    draw_section "GIT CONFIGURATION"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would configure Git"
        return 0
    fi

    if [[ -n "${GIT_USERNAME:-}" ]] && [[ -n "${GIT_EMAIL:-}" ]]; then
        git config --global user.name "$GIT_USERNAME"
        git config --global user.email "$GIT_EMAIL"
        log_success "Git configured: ${GIT_USERNAME} <${GIT_EMAIL}>"
    else
        if ! git config --global user.name &>/dev/null; then
            log_info "Git user.name not set. Skipping. Set with:"
            log_info "  git config --global user.name 'Your Name'"
            log_info "  git config --global user.email 'your@email.com'"
        else
            log_info "Git already configured: $(git config --global user.name)"
        fi
    fi

    git config --global init.defaultBranch main
    git config --global pull.rebase true
    git config --global fetch.prune true
    git config --global diff.colorMoved zebra
    log_success "Git options configured"
}

setup_node() {
    draw_section "NODE.JS SETUP"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Node.js and Bun"
        return 0
    fi

    if ! command -v node &>/dev/null; then
        log_info "Installing Node.js..."
        if command -v fnm &>/dev/null; then
            fnm install --lts &>/dev/null
        elif command -v nvm &>/dev/null; then
            nvm install --lts &>/dev/null
        else
            pkg_install nodejs
        fi
    else
        log_info "Node.js $(node --version) already installed"
    fi

    if ! command -v bun &>/dev/null; then
        log_info "Installing Bun..."
        curl -fsSL https://bun.sh/install | bash &>/dev/null || log_warn "Bun install failed"
    else
        log_info "Bun already installed"
    fi

    if ! command -v pnpm &>/dev/null; then
        log_info "Installing pnpm..."
        npm install -g pnpm &>/dev/null || true
    fi

    log_success "Node.js tooling ready"
}

setup_rust() {
    draw_section "RUST SETUP"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Rust"
        return 0
    fi

    if ! command -v rustc &>/dev/null; then
        log_info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
        source "$HOME/.cargo/env" 2>/dev/null || true
    fi

    if command -v rustc &>/dev/null; then
        log_success "Rust $(rustc --version) ready"
    else
        log_error "Rust installation failed"
    fi
}

setup_go() {
    draw_section "GO SETUP"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Go"
        return 0
    fi

    if ! command -v go &>/dev/null; then
        pkg_install go
    fi

    if command -v go &>/dev/null; then
        log_success "Go $(go version | awk '{print $3}') ready"
    fi
}

setup_python() {
    draw_section "PYTHON SETUP"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would configure Python"
        return 0
    fi

    if ! command -v pip3 &>/dev/null; then
        pkg_install python3-pip || pkg_install python-pip || true
    fi

    if ! command -v pipx &>/dev/null; then
        pip3 install --user pipx &>/dev/null || true
        export PATH="$PATH:$HOME/.local/bin"
    fi

    log_success "Python tooling ready"
}

setup_ssh() {
    draw_section "SSH KEY GENERATION"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would generate SSH keys"
        return 0
    fi

    local ssh_dir="$HOME/.ssh"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    if [[ ! -f "$ssh_dir/id_ed25519" ]]; then
        local email="${GIT_EMAIL:-commander@kernelghost.dev}"
        log_info "Generating Ed25519 SSH key for GitHub..."
        ssh-keygen -t ed25519 -C "$email" -f "$ssh_dir/id_ed25519" -N "" &>/dev/null
        log_success "SSH key generated: ${ssh_dir}/id_ed25519.pub"
        log_info "Public key:"
        cat "$ssh_dir/id_ed25519.pub"
        log_info ""
        log_info "Add this key to: https://github.com/settings/keys"
    else
        log_info "SSH key already exists"
    fi
}

setup_development() {
    setup_git
    setup_node
    setup_rust
    setup_go
    setup_python
    setup_ssh
}
