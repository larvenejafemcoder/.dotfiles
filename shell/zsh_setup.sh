#!/usr/bin/env bash
set -euo pipefail

info()  { echo -e "\033[0;36m[INFO]\033[0m $1"; }
ok()    { echo -e "\033[0;32m[OK]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# 1. Ensure zsh is installed
if ! command -v zsh &>/dev/null; then
    warn "zsh not found. Installing..."
    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm zsh
    elif command -v apt &>/dev/null; then
        sudo apt install -y zsh
    fi
else
    ok "zsh is already installed"
fi

# 2. Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed"
else
    ok "Oh My Zsh already installed"
fi

# 3. Install Powerlevel10k theme
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    ok "Powerlevel10k installed"
else
    ok "Powerlevel10k already installed"
fi

# 4. Install Fira Code Medium Nerd Font
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

BASE_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Medium"

FONTS=(
    "Fira Code Medium Nerd Font Complete.ttf"
    "Fira Code Medium Nerd Font Complete Mono.ttf"
    "Fira Code Medium Nerd Font Complete.otf"
    "Fira Code Medium Nerd Font Complete Mono.otf"
)

info "Installing Fira Code Medium Nerd Fonts..."
for font in "${FONTS[@]}"; do
    curl -fLo "$FONT_DIR/$font" "$BASE_URL/$font" 2>/dev/null || warn "Failed to download $font"
done

fc-cache -f 2>/dev/null
ok "Font cache updated"

# 5. Set default shell to zsh if not already
if [ "$SHELL" != "$(which zsh)" ]; then
    info "To set zsh as default shell, run: chsh -s $(which zsh)"
fi

ok "Zsh setup complete"
