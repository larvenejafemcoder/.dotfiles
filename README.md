# KernelGhost Dotfiles

Personal Linux configuration for terminal setups, theming, and desktop environments.
Built for Arch-based systems, compatible with Ubuntu/Debian and Fedora.

## Quick Start

```bash
git clone https://github.com/larvenejafemcoder/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

## Structure

```
.dotfiles/
├── install.sh                           # Main installer (orchestrates everything)
├── bootstrap.sh                         # Distro detection + package installation
├── deploy.sh                            # Symlink deployment (via GNU Stow)
├── stow/                                # Config files (stow-compatible)
│   ├── alacritty/.config/alacritty/     # Alacritty terminal config + themes
│   ├── bash/.bashrc                     # Bash shell config
│   ├── fastfetch/.config/fastfetch/     # Fastfetch system info config
│   ├── fish/.config/fish/config.fish    # Fish shell config (SSH agent)
│   ├── kitty/.config/kitty/             # Kitty terminal config + themes
│   ├── neofetch/.config/neofetch/       # Neofetch config + profile images
│   ├── starship/.config/starship.toml   # Starship prompt (catppuccin-powerline)
│   └── zsh/.config/zsh/                 # Zsh config + aliases
├── shell/
│   ├── zsh_setup.sh                     # Oh My Zsh + Powerlevel10k installer
│   ├── starship_setup.sh                # Starship prompt installer
│   └── rice.sh                          # Gruvbox ricing (theme, icons, extensions, wallpaper)
├── themes/
│   ├── tahoe-theme/                     # macOS Tahoe GNOME theme
│   └── whitesur-All/                    # WhiteSur GTK theme
├── fonts/
│   ├── font.sh                          # Nerd Font downloader
│   └── Meslo/                           # Meslo LG Nerd Font files + installer
├── gnome-terminal/                      # GNOME Terminal dconf backup
└── LICENSE                              # MIT License
```

## Flags

| Flag | Description |
|------|-------------|
| `--minimal` | Symlink configs only (skip packages, themes, fonts) |
| `--rice` | Also run the Gruvbox ricing script (theme, icons, extensions, wallpaper) |
| `--no-theme` | Skip GNOME theme installation |
| `--no-fonts` | Skip font installation |
| `--no-starship` | Skip Starship prompt |
| `--no-zsh` | Skip Zsh/Oh My Zsh setup |

## Manual Install

```bash
ln -s ~/.dotfiles/stow/alacritty/.config/alacritty ~/.config/alacritty
ln -s ~/.dotfiles/stow/fish/.config/fish ~/.config/fish
ln -s ~/.dotfiles/stow/zsh/.zshrc ~/.zshrc
ln -s ~/.dotfiles/stow/bash/.bashrc ~/.bashrc
```

Or use GNU Stow:

```bash
cd ~/.dotfiles/stow
stow -t ~ alacritty fish kitty fastfetch neofetch zsh bash starship
```

## Requirements

**Arch:**
```bash
sudo pacman -S zsh curl alacritty kitty fish stow dconf git unzip
```

**Debian/Ubuntu:**
```bash
sudo apt install zsh curl git stow dconf-cli unzip fish kitty
```

## Features

- **Terminals**: Alacritty (primary) + Kitty with Nordic/Dank themes
- **Shells**: Zsh (Oh My Zsh + Powerlevel10k), Fish, Bash
- **Prompt**: Starship with Catppuccin Powerline preset
- **Fetch**: fastfetch + neofetch with custom images
- **Themes**: Tahoe (macOS) + WhiteSur GNOME themes
- **Fonts**: MesloLG Nerd Font + Fira Code Nerd Font
- **Standards**: Wayland-first, GNOME-friendly, reproducible setup
