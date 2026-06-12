#!/usr/bin/env bash
set -euo pipefail

info()  { echo -e "\033[0;36m[INFO]\033[0m $1"; }
ok()    { echo -e "\033[0;32m[OK]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# Install Starship binary
if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    ok "Starship installed"
else
    ok "Starship already installed"
fi

# Generate catppuccin-powerline preset as default config
if command -v starship &>/dev/null; then
    info "Generating Starship config (catppuccin-powerline)..."
    mkdir -p "$HOME/.config"
    starship preset catppuccin-powerline -o "$HOME/.config/starship.toml" 2>/dev/null || \
        warn "Could not generate preset, using existing config"
    ok "Starship config generated"
fi

ok "Starship setup complete"
