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

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$DOTFILES_DIR/stow"

deploy_with_stow() {
    info "Deploying configs with GNU Stow..."
    local packages=()
    for pkg in "$STOW_DIR"/*/; do
        packages+=("$(basename "$pkg")")
    done

    cd "$STOW_DIR"
    for pkg in "${packages[@]}"; do
        if stow -R --no-folding -t "$HOME" "$pkg" 2>/dev/null; then
            ok "Linked: $pkg"
        else
            warn "Failed to link: $pkg"
        fi
    done
    cd "$DOTFILES_DIR"
}

deploy_manual() {
    info "Deploying configs manually (stow not found)..."
    for package_dir in "$STOW_DIR"/*/; do
        pkg_name="$(basename "$package_dir")"
        info "Deploying $pkg_name..."
        find "$package_dir" -type f | while read -r file; do
            rel_path="${file#$package_dir}"
            target="$HOME/$rel_path"
            mkdir -p "$(dirname "$target")"
            if [ -f "$target" ] && [ ! -L "$target" ]; then
                mv "$target" "${target}.bak"
                warn "Backed up $target -> ${target}.bak"
            fi
            ln -sf "$file" "$target"
            ok "Linked ~/$rel_path"
        done
    done
}

deploy_symlinks() {
    mkdir -p "$HOME/.config"

    if command -v stow &>/dev/null; then
        deploy_with_stow
    else
        warn "GNU Stow not found, using manual symlink creation."
        deploy_manual
    fi

    ok "All config symlinks deployed"
}

deploy_symlinks
