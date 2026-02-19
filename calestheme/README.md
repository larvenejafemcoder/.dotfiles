

# Calestheme – KernelGhost Edition

Calestheme is a compositor-agnostic Caelestia fork maintained by KernelGhost.

It provides a unified visual and workflow layer across:

* Hyprland
* Niri

The goal is deterministic keyboard-driven workflow with consistent aesthetics across compositors.

---

## Features

* Unified theme across terminal, shell, browser, editor
* Hyprland and Niri support
* Symlink-based deployment
* Arch-native packaging (PKGBUILD included)
* Fish + Starship integration
* Optional Spotify, VSCode, Zen support

---

# Installation

## Method 1 – Automatic (Recommended)

### Step 1 – Install dependencies

On Arch / Arch-based systems:

```bash
sudo pacman -S --needed \
  fish foot fastfetch btop jq eza starship \
  hyprland niri \
  wl-clipboard cliphist hyprpicker \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  wireplumber trash-cli \
  adw-gtk-theme papirus-icon-theme \
  qt5ct-kde qt6ct-kde \
  ttf-jetbrains-mono-nerd
```

(Optional AUR helper: `yay` or `paru`)

---

### Step 2 – Clone the repository

```bash
git clone https://github.com/<your-username>/calestheme.git \
  ~/.local/share/calestheme
```

---

### Step 3 – Run the installer

```bash
cd ~/.local/share/calestheme
./install.fish --compositor=hypr
```

or

```bash
./install.fish --compositor=niri
```

---

⚠ Important:

The installer uses symlinks.

Do NOT move or delete the repository after installation.

Recommended location:

```
~/.local/share/calestheme
```

---

# Installation Options

```
./install.fish [OPTIONS]

--compositor=[hypr|niri]
--noconfirm
--spotify
--vscode=[code|codium]
--discord
--zen
--aur-helper=[yay|paru]
```

Example:

```bash
./install.fish --compositor=niri --vscode=codium --spotify
```

---

# Method 2 – Using PKGBUILD (Arch users)

Inside the repository:

```bash
makepkg -si
```

Or with AUR helper:

```bash
yay -S kernelghost-calestheme
```

This installs dependencies and runs the install script.

---

# Manual Installation

If you prefer manual control:

### 1. Install dependencies (see list above)

### 2. Symlink configs

```bash
ln -s ~/calestheme/hypr ~/.config/hypr
ln -s ~/calestheme/niri ~/.config/niri
ln -s ~/calestheme/fish ~/.config/fish
ln -s ~/calestheme/foot ~/.config/foot
ln -s ~/calestheme/btop ~/.config/btop
ln -s ~/calestheme/fastfetch ~/.config/fastfetch
ln -s ~/calestheme/micro ~/.config/micro
ln -s ~/calestheme/thunar ~/.config/thunar
ln -s ~/calestheme/uwsm ~/.config/uwsm
ln -s ~/calestheme/vscode ~/.config/Code/User
```

Copy Starship:

```bash
cp starship.toml ~/.config/starship.toml
```

---

# Compositor Selection Logic

Hyprland and Niri are configured to share:

* Color palette
* Terminal integration
* Keybinding philosophy
* Launcher behavior

Muscle memory remains consistent across compositors.

---

# Updating

```bash
cd ~/.local/share/calestheme
git pull
```

Then update packages:

```bash
yay -Syu
```

---

# Design Philosophy

Calestheme is built around:

* Minimal visual noise
* High keyboard throughput
* Consistent workspace logic
* Arch-native reproducibility
* Compositor flexibility without aesthetic fragmentation

---

# Notes

No login manager is included.

Recommended:

* greetd
* tuigreet

Or log in via TTY if preferred.


