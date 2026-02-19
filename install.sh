#!/usr/bin/env bash
set -e



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting install..."

# Install packages
if command -v pacman >/dev/null 2>&1; then
    echo "Arch-based system detected"
    sudo pacman -Syu
    echo "Updating"
    sudo pacman -S --needed alacritty zsh curl dconf fish
elif command -v apt >/dev/null 2>&1; then
    echo "Debian-based system detected"
    echo "Updating"
    sudo apt update
    sudo apt install -y alacritty zsh curl dconf fish
else
    echo "Unsupported system"
    exit 1
fi

# Install Alacritty config
echo "Installing Alacritty config..."
mkdir -p ~/.config
cp -r "$SCRIPT_DIR/alacritty" ~/.config/

# Install calestheme (fish installer)

echo "Installing fonts..."

if [ -f "$SCRIPT_DIR/fonts/font.sh" ]; then
    (
        cd "$SCRIPT_DIR/fonts"
        bash font.sh
    )
else
    echo "fonts/font.sh not found."
fi


echo "Installing Tahoe GNOME theme..."

if [ -d "$SCRIPT_DIR/tahoe-theme" ]; then
    (
        echo "Installing Tahoe theme... please wait"
        cd "$SCRIPT_DIR/tahoe-theme"
        bash install.sh
        echo "3"
        echo "2"
        echo "1....Done"
    )
else
    echo "Tahoe-theme directory not found."
fi

curl -fsSL https://install.danklinux.com | sh

echo "Done."