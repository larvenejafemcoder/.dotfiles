#!/usr/bin/env bash
set -e

echo "Starting krnl_terminal setup"

# 1. Ensure zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
  echo "Installing zsh via yay"
  yay -S --noconfirm zsh
else
  echo "zsh is already installed"
fi

# 2. Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh is already installed"
fi

# 3. Install Powerlevel10k theme
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "Installing Powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "Powerlevel10k is already installed"
fi

# 4. Configure Powerlevel10k as default theme
if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
  sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
else
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
fi

# 5. Configure plugins
if grep -q '^plugins=' "$HOME/.zshrc"; then
  sed -i 's/^plugins=.*/plugins=(git z sudo extract)/' "$HOME/.zshrc"
else
  echo 'plugins=(git z sudo extract)' >> "$HOME/.zshrc"
fi

# 6. Install Fira Code Medium Nerd Font
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

BASE_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Medium"

FONTS=(
  "Fira Code Medium Nerd Font Complete.ttf"
  "Fira Code Medium Nerd Font Complete Mono.ttf"
  "Fira Code Medium Nerd Font Complete.otf"
  "Fira Code Medium Nerd Font Complete Mono.otf"
)

echo "Installing Fira Code Medium Nerd Fonts"
for font in "${FONTS[@]}"; do
  curl -fLo "$FONT_DIR/$font" "$BASE_URL/$font"
done

fc-cache -fv

echo "krnl_terminal setup finished"
echo
echo "Next steps:"
echo "- Set terminal font to Fira Code Medium Nerd Font (or Mono variant)"
echo "- Restart your terminal"
echo "- Run: exec zsh"
echo "- Complete the Powerlevel10k configuration on first launch"