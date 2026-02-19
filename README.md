


# KernelGhost Dotfiles

Personal Linux configuration repository for terminal setups, theming, and compositor environments.

Built mainly for Arch-based systems, but partially compatible with Ubuntu / Debian.

This repo exists for one reason:
I refuse to spend 3 hours reconfiguring my terminal every time I reinstall Linux.

---

## Scope

This repository contains:

- Terminal configs (Alacritty, GNOME Terminal)
- Shell environments (Zsh, Fish, Starship)
- System theming (GTK, icons, fonts)
- Fetch setups (fastfetch / neofetch)
- Compositor-related configs (via `calestheme/`)
- An install script for reproducible setup

It acts as the source of truth for my user-level Linux environment.

---

## Philosophy

- Keyboard-first workflow  
- Minimal visual noise  
- Modular structure  
- Reproducible setup  
- Arch-native tooling  
- No overengineering  

Not claiming this is perfect.
It’s just stable, predictable, and mine.

---

## Repository Structure

```text
.
├── alacritty/
├── calestheme/
├── fastfetch/
├── fonts/
├── gnome-terminal/
├── neofetch/
├── starship/
├── tahoe-theme/
├── Tahoe-icons/
├── whitesur-All/
├── zsh/
├── config.fish
├── install.sh
├── LICENSE
└── README.md
```

### Notable Directories

**calestheme/**  
Unified theme layer (Hyprland / Niri compatible).

**alacritty/**  
Primary terminal configuration.

**zsh/**  
Shell configuration, aliases, plugins.

**gnome-terminal/**  
GNOME Terminal profile backup via `dconf`.

**fonts/**  
Font layer (JetBrains Mono Nerd, etc).

---

# Installation

## Quick Install

```bash
git clone https://github.com/larvenejafemcoder/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

The install script symlinks configs into place.

⚠ Do not move or delete the repo directory after installation if using symlinks.

---

## Manual Install (Full Control)

Clone:

```bash
git clone https://github.com/larvenejafemcoder/dotfiles.git ~/.dotfiles
```

Example symlinks:

```bash
ln -s ~/.dotfiles/zsh ~/.config/zsh
ln -s ~/.dotfiles/alacritty ~/.config/alacritty
ln -s ~/.dotfiles/fastfetch ~/.config/fastfetch
ln -s ~/.dotfiles/config.fish ~/.config/fish/config.fish
```

---

## Requirements

Install core dependencies before running the installer.

### Arch-based

```bash
sudo pacman -S zsh curl alacritty dconf
```

### Ubuntu / Debian

```bash
sudo apt install zsh curl alacritty dconf-cli
```

Additional packages may be required depending on which components you use.

---

## GNOME Terminal Backup / Restore

Export:

```bash
dconf dump /org/gnome/terminal/ > gnome-terminal/gnome-terminal.dconf
```

Restore:

```bash
dconf load /org/gnome/terminal/ < gnome-terminal/gnome-terminal.dconf
```

This alone makes the repo worth keeping.

---

## Updating

```bash
cd ~/.dotfiles
git pull
```

System packages:

```bash
sudo pacman -Syu
```

or

```bash
sudo apt update && sudo apt upgrade
```

---

## Notes

- Tested mainly on Arch Linux
- Wayland-first environment
- GNOME-friendly
- Structure may evolve over time

This is a living configuration repo.
If something breaks, future me will fix it.

---
