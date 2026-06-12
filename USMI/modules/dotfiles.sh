#!/usr/bin/env bash
# ── USMI Module: Config Deployment ──
# Deploys dotfiles from USMI/configs/ to $HOME

USMI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="$(cd "$USMI_DIR/.." && pwd)"

deploy_config() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"

    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        log_debug "Symlink already correct: $dest"
        return 0
    fi

    if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
        local backup="${dest}.bak-$(date +%Y%m%d)"
        mv "$dest" "$backup"
        log_info "Backed up: $dest → $backup"
    fi

    rm -f "$dest"
    ln -sf "$src" "$dest"
    log_success "Linked: $dest → $src"
}

deploy_zsh() {
    local src="$USMI_DIR/configs/zsh"
    if [[ -f "$src/.zshrc" ]]; then
        deploy_config "$src/.zshrc" "$HOME/.zshrc"
    fi
}

deploy_git() {
    local src="$USMI_DIR/configs/git"
    if [[ -f "$src/.gitconfig" ]]; then
        deploy_config "$src/.gitconfig" "$HOME/.gitconfig"
    fi
    if [[ -f "$src/.gitignore" ]]; then
        deploy_config "$src/.gitignore" "$HOME/.gitignore"
    fi
}

deploy_nvim() {
    local src="$USMI_DIR/configs/nvim"
    if [[ -d "$src" ]]; then
        deploy_config "$src" "$HOME/.config/nvim"
    fi
}

deploy_tmux() {
    local src="$USMI_DIR/configs/tmux"
    if [[ -f "$src/.tmux.conf" ]]; then
        deploy_config "$src/.tmux.conf" "$HOME/.tmux.conf"
    fi
}

deploy_all() {
    draw_section "CONFIG DEPLOYMENT"
    log_info "Deploying configs from USMI/configs/..."

    deploy_zsh
    deploy_git
    deploy_nvim
    deploy_tmux

    log_success "Configs deployed"
}

# If USMI/configs/ is empty, try to use existing dotfiles configs
populate_configs_from_existing() {
    local populated=false

    if [[ ! -f "$USMI_DIR/configs/zsh/.zshrc" ]] && [[ -d "$DOTFILES_DIR/irichu-config/zsh" ]]; then
        mkdir -p "$USMI_DIR/configs/zsh"
        cp -r "$DOTFILES_DIR/irichu-config/zsh/." "$USMI_DIR/configs/zsh/" 2>/dev/null
        populated=true
    fi

    if [[ ! -d "$USMI_DIR/configs/nvim" ]] && [[ -d "$DOTFILES_DIR/irichu-config/nvim" ]]; then
        cp -r "$DOTFILES_DIR/irichu-config/nvim" "$USMI_DIR/configs/" 2>/dev/null
        populated=true
    fi

    if [[ ! -f "$USMI_DIR/configs/git/.gitconfig" ]] && [[ -d "$DOTFILES_DIR/irichu-config/git" ]]; then
        mkdir -p "$USMI_DIR/configs/git"
        cp -r "$DOTFILES_DIR/irichu-config/git/." "$USMI_DIR/configs/git/" 2>/dev/null
        populated=true
    fi

    if [[ ! -f "$USMI_DIR/configs/tmux/.tmux.conf" ]] && [[ -d "$DOTFILES_DIR/irichu-config/tmux" ]]; then
        mkdir -p "$USMI_DIR/configs/tmux"
        cp -r "$DOTFILES_DIR/irichu-config/tmux/." "$USMI_DIR/configs/tmux/" 2>/dev/null
        populated=true
    fi

    if $populated; then
        log_success "Populated USMI/configs/ from existing dotfiles"
    fi
}

create_dev_directories() {
    draw_section "PERSONAL ENVIRONMENT"
    log_info "Creating development directories..."
    mkdir -p "$HOME/Development"/{C,CPP,Rust,Python,Web,AI,Homelab,Docker,Go,Zig}
    log_success "Development folders created"
}

setup_ssh() {
    local ssh_dir="$HOME/.ssh"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    if [[ ! -f "$ssh_dir/id_ed25519" ]]; then
        log_info "Generating Ed25519 SSH key..."
        ssh-keygen -t ed25519 -C "usmi@${HOSTNAME}" -f "$ssh_dir/id_ed25519" -N "" 2>/dev/null || true
        log_success "SSH key generated: $ssh_dir/id_ed25519.pub"
        cat "$ssh_dir/id_ed25519.pub"
    else
        log_info "SSH key already exists"
    fi
}

setup_git_config() {
    if is_installed git; then
        if ! git config --global user.name &>/dev/null; then
            read -rp "  Git user name: " git_name
            git config --global user.name "$git_name"
        fi
        if ! git config --global user.email &>/dev/null; then
            read -rp "  Git email: " git_email
            git config --global user.email "$git_email"
        fi
        git config --global init.defaultBranch main 2>/dev/null || true
        git config --global pull.rebase true 2>/dev/null || true
        log_success "Git configured"
    fi
}
