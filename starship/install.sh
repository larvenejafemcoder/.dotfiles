#!/usr/bin/env bash
set -e

echo "Installing Starship..."
n=5

for ((i = 1; i <= n; i++)); do
  echo " $i"
done

# Install Starship
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "Starship installed."

# Ensure config directory exists
mkdir -p "$HOME/.config"

echo "Creating Starship config..."
starship preset catppuccin-powerline -o "$HOME/.config/starship.toml"

echo "Detecting shell..."
SHELL_NAME=$(basename "$SHELL")
echo "Detected shell: $SHELL_NAME"

# Persist initialization
case "$SHELL_NAME" in
  bash)
    if ! grep -q "starship init bash" "$HOME/.bashrc"; then
      echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
      echo "Added Starship to .bashrc"
    fi
    ;;
  zsh)
    if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
      echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
      echo "Added Starship to .zshrc"
    fi
    ;;
  fish)
    mkdir -p "$HOME/.config/fish"
    if ! grep -q "starship init fish" "$HOME/.config/fish/config.fish" 2>/dev/null; then
      echo 'starship init fish | source' >> "$HOME/.config/fish/config.fish"
      echo "Added Starship to fish config"
    fi
    ;;
  *)
    echo "Unsupported shell for auto-init."
    ;;
esac

echo "Starship installation complete."
echo "Restart your terminal or run: exec $SHELL"