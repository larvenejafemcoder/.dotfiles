#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

INSTALL_THEME=true
INSTALL_FONTS=true
INSTALL_STARSHIP=true
INSTALL_ZSH=true
INSTALL_RICE=false
MINIMAL=false

for arg in "$@"; do
    case $arg in
        --minimal)
            MINIMAL=true
            INSTALL_THEME=false
            INSTALL_FONTS=false
            INSTALL_STARSHIP=false
            INSTALL_ZSH=false
            shift
            ;;
        --rice)
            INSTALL_RICE=true
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
        --no-zsh)
            INSTALL_ZSH=false
            shift
            ;;
        --help)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --minimal        Symlink configs only (no packages/fonts/themes)"
            echo "  --rice           Also run gruvbox ricing script (themes, icons, extensions, wallpaper)"
            echo "  --no-theme       Skip GNOME theme install"
            echo "  --no-fonts       Skip fonts install"
            echo "  --no-starship    Skip Starship prompt install"
            echo "  --no-zsh         Skip Zsh/Oh My Zsh setup"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

cat << 'EOF'
╔══════════════════════════════════════╗
║        KernelGhost Dotfiles          ║
║     Automated Setup                  ║
╚══════════════════════════════════════╝
EOF

if [ "$MINIMAL" = false ]; then
    # 1. Bootstrap packages
    info "Step 1: Installing system packages..."
    source "$DOTFILES_DIR/bootstrap.sh"
    install_packages

    # 2. Install fonts
    if [ "$INSTALL_FONTS" = true ]; then
        info "Step 2: Installing fonts..."
        if [ -f "$DOTFILES_DIR/fonts/font.sh" ]; then
            bash "$DOTFILES_DIR/fonts/font.sh"
        fi
        if [ -f "$DOTFILES_DIR/fonts/Meslo/install.sh" ]; then
            bash "$DOTFILES_DIR/fonts/Meslo/install.sh"
        fi
    fi

    # 3. Zsh setup (Oh My Zsh + Powerlevel10k)
    if [ "$INSTALL_ZSH" = true ]; then
        info "Step 3: Setting up Zsh..."
        if [ -f "$DOTFILES_DIR/shell/zsh_setup.sh" ]; then
            bash "$DOTFILES_DIR/shell/zsh_setup.sh"
        fi
    fi

    # 4. Starship prompt
    if [ "$INSTALL_STARSHIP" = true ]; then
        info "Step 4: Installing Starship prompt..."
        if [ -f "$DOTFILES_DIR/shell/starship_setup.sh" ]; then
            bash "$DOTFILES_DIR/shell/starship_setup.sh"
        fi
    fi
fi

# 5. Deploy config symlinks (always runs)
info "Step 5: Deploying config symlinks..."
bash "$DOTFILES_DIR/deploy.sh"

if [ "$MINIMAL" = false ]; then
    # 6. Install themes
    if [ "$INSTALL_THEME" = true ]; then
        info "Step 6: Installing GNOME themes..."
        if [ -d "$DOTFILES_DIR/themes/tahoe-theme" ] && [ -f "$DOTFILES_DIR/themes/tahoe-theme/install.sh" ]; then
            bash "$DOTFILES_DIR/themes/tahoe-theme/install.sh"
        fi
        if [ -d "$DOTFILES_DIR/themes/whitesur-All" ] && [ -f "$DOTFILES_DIR/themes/whitesur-All/install.sh" ]; then
            bash "$DOTFILES_DIR/themes/whitesur-All/install.sh"
        fi
    fi

    # 7. Restore GNOME Terminal profile
    if [ -f "$DOTFILES_DIR/gnome-terminal/gnome-terminal.dconf" ] && [ -s "$DOTFILES_DIR/gnome-terminal/gnome-terminal.dconf" ]; then
        info "Restoring GNOME Terminal profile..."
        if command -v dconf &>/dev/null; then
            dconf load /org/gnome/terminal/ < "$DOTFILES_DIR/gnome-terminal/gnome-terminal.dconf"
            ok "GNOME Terminal profile restored"
        fi
    fi
fi

# 8. Rice (Gruvbox theme, extensions, wallpaper)
if [ "$INSTALL_RICE" = true ]; then
    info "Step 8: Running Gruvbox ricing script..."
    if [ -f "$DOTFILES_DIR/shell/rice.sh" ]; then
        bash "$DOTFILES_DIR/shell/rice.sh"
    fi
fi

ok "Installation complete!"
echo ""
echo "  Next steps:"
echo "   1. Restart your terminal"
echo "   2. Run: chsh -s \$(which zsh)  (to set Zsh as default shell)"
echo "   3. Run: exec zsh"
echo "   4. Complete the Powerlevel10k configuration prompt"
echo ""
