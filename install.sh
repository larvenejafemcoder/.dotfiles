#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===============================
# Default Options
# ===============================
INSTALL_THEME=true
INSTALL_FONTS=true
INSTALL_STARSHIP=true
MINIMAL=false

# ===============================
# Parse CLI Arguments
# ===============================
for arg in "$@"; do
    case $arg in
        --minimal)
            MINIMAL=true
            INSTALL_THEME=false
            INSTALL_FONTS=false
            INSTALL_STARSHIP=false
            shift
            ;;
        --no-theme)
            INSTALL_THEME=false
            shift
            ;;
        --no-fonts)
            INSTALL_FONTS=false
            shift
            ;;
        --no-starship)
            INSTALL_STARSHIP=false
            shift
            ;;
        --help)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --minimal        Install only core packages + Alacritty config"
            echo "  --no-theme       Skip GNOME theme install"
            echo "  --no-fonts       Skip fonts install"
            echo "  --no-starship    Skip Starship install"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

echo "Starting install..."

# ===============================
# Install Packages
# ===============================
if command -v pacman >/dev/null 2>&1; then
    echo "Arch-based system detected"
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm alacritty zsh curl dconf fish
elif command -v apt >/dev/null 2>&1; then
    echo "Debian-based system detected"
    sudo apt update
    sudo apt install -y alacritty zsh curl dconf fish
else
    echo "Unsupported system"
    exit 1
fi

# ===============================
# Install Alacritty Config
# ===============================
echo "Installing Alacritty config..."
mkdir -p ~/.config/alacritty
cp -r "$SCRIPT_DIR/alacritty/." ~/.config/alacritty/

# ===============================
# Install Fonts
# ===============================
if [ "$INSTALL_FONTS" = true ]; then
    echo "Installing fonts..."
    if [ -f "$SCRIPT_DIR/fonts/font.sh" ]; then
        (
            cd "$SCRIPT_DIR/fonts"
            bash font.sh
        )
    else
        echo "fonts/font.sh not found."
    fi
fi

# ===============================
# Install Starship
# ===============================
if [ "$INSTALL_STARSHIP" = true ]; then
    echo "Installing Starship..."
    if [ -f "$SCRIPT_DIR/starship/install.sh" ]; then
        (
            cd "$SCRIPT_DIR/starship"
            bash install.sh
        )
    else
        echo "starship/install.sh not found."
    fi
fi

# ===============================
# Install Tahoe GNOME Theme
# ===============================
if [ "$INSTALL_THEME" = true ]; then
    echo "Installing Tahoe GNOME theme..."
    if [ -d "$SCRIPT_DIR/tahoe-theme" ]; then
        (
            cd "$SCRIPT_DIR/tahoe-theme"
            bash install.sh
        )
    else
        echo "tahoe-theme directory not found."
    fi
fi

curl -fsSL https://install.danklinux.com | sh

echo "Done."