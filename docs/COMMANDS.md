# Commands

> **Applies to:** `install.sh`

---

## Summary

| Flag | Mode | Purpose |
|------|------|---------|
| `--setup` / `--interactive` | Interactive | Full interactive menu (dotfiles + tools) |
| `--dotfiles-only` | Interactive | Dotfile selection only |
| `--tools-only` | Interactive | Dev tool selection only |
| `--repeat` | Interactive | Re-apply last saved selections |
| `--offline` | Interactive | Skip all downloads |
| `--force` | Both | Overwrite without confirmation |
| `--tui` | TUI | Launch Textual Python TUI |
| `--unattended` | Automated | Full headless install |
| `--dry-run` | Automated | Simulate without changes |
| `--rollback` | Automated | Roll back previous symlink deployment |
| `--debug` | Automated | Verbose output |
| `--minimal` | Automated | Config symlinks only |
| `--profile <name>` | Automated | Desktop environment profile |
| `--rice` | Automated | Apply Gruvbox ricing |
| `--no-*` flags | Automated | Skip individual components |
| `--git-name`, `--git-email` | Both | Configure Git |
| `--help` / `-h` | — | Print usage |

---

## Interactive Mode

### `./install.sh --setup`

Full interactive menu powered by dialog/whiptail:

```
┌──────────────────────────────────┐
│   Dotfiles & Dev Tools — Setup   │
├──────────────────────────────────┤
│ 1. Install / update dotfiles     │
│ 2. Install development tools     │
│ 3. Exit                          │
└──────────────────────────────────┘
```

Selecting **dotfiles** opens a checklist of available config files:
```
┌── Select Dotfiles ──────────────────────────────────────────────┐
│ [ ] __all__  Install ALL available dotfiles                     │
│ [*] .zshrc   Zsh configuration                                  │
│ [ ] .bashrc  Bash configuration                                 │
│ [*] .tmux.conf Tmux configuration                               │
│ [*] .config/alacritty Alacritty terminal config                 │
│ [ ] .config/starship.toml Starship prompt config                │
│ ...                                                             │
├─────────────────────────────────────────────────────────────────┤
│          <OK>              <Cancel>                             │
└─────────────────────────────────────────────────────────────────┘
```

After symlinking, prompts to run GNU Stow for stow-managed packages:
```
┌── GNU Stow ────────────────┐
│ Run stow for all packages? │
│ Packages: alacritty bash   │
│ fastfetch fish kitty       │
│ neofetch starship zsh      │
│   <Yes>      <No>          │
└────────────────────────────┘
```

Selecting **tools** opens the dev tools checklist:
```
┌── Dev Tools ──────────────────────────────────────────────────────────┐
│  ─── Languages ───                                                    │
│ [ ] nodejs   Node.js via nvm                                          │
│ [*] rust     Rust via rustup                                          │
│ [ ] go       Go language                                              │
│  ─── Terminal ───                                                     │
│ [*] starship Starship prompt                                           │
│ [ ] tmux     Tmux + TPM                                               │
│  ─── Editors ───                                                      │
│ [ ] neovim   Neovim (latest)                                          │
│  ─── DevOps ───                                                       │
│ [ ] docker   Docker + Compose                                         │
│  ─── Utilities ───                                                    │
│ [*] cli      eza, bat, fzf, ripgrep, fd, lazygit, jq, httpie, zoxide │
└───────────────────────────────────────────────────────────────────────┘
```

### `./install.sh --dotfiles-only`

Skips the main menu, goes directly to the dotfiles checklist. After completion,
displays a summary:

```
OK    Dotfiles installed: 5 files
  ✓ .zshrc → /home/user/.zshrc
  ✓ .tmux.conf → /home/user/.tmux.conf
  ✓ .config/alacritty → /home/user/.config/alacritty
```

### `./install.sh --tools-only`

Skips the main menu, goes directly to the tools checklist.

### `./install.sh --repeat`

Reads `~/.config/dotfiles-setup/selections.cfg` and re-applies the saved
selections without showing any TUI prompts. Useful for syncing after checkout
on a new machine.

```bash
# On machine A:
./install.sh --dotfiles-only    # saves selections

# On machine B (after git pull):
./install.sh --repeat           # re-applies same selections
```

### `./install.sh --offline`

Modifier flag. Adds a check in every install function:

```bash
[ "$OFFLINE" = 1 ] && { setup_warn "Offline — skipping: $package"; return 0; }
```

Use with `--setup` or `--repeat` to skip downloads while still symlinking
dotfiles and installing packages from local cache.

### `./install.sh --force`

Modifier flag. Currently reserved — future use will suppress confirmation
prompts during symlink overwrite.

---

## TUI Mode

### `./install.sh --tui`

Launches the **Textual** Python TUI. This bootstraps a Python virtual
environment:

```
╔═══════════════════════════════════╗
║     Dotfiles Setup Utility        ║
╚═══════════════════════════════════╝
  ✓ Python 3.12.3
  ✓ Virtual environment ready
  ✓ Installing Textual...
  ✓ Starting TUI...
```

Then opens `main.py` which provides a richer interface with:
- Animated startup loading screen
- System check screen
- Component selector with categories
- Profile selection
- Install progress with block animations

Requires Python 3.10+ and internet (first run only, for pip packages).

---

## Automated Mode

### `./install.sh --unattended`

Runs the full pipeline without any user interaction:

```bash
# CI / first-time setup
./install.sh --unattended
```

Pipeline:
1. Draw boot screen
2. Detect OS, distro, DE, terminal
3. Update package lists, install packages from `config/packages/$DISTRO.txt`
4. Deploy dotfile symlinks
5. Install Zsh + Starship (if enabled)
6. Install Meslo Nerd Font
7. Install dev tools (Node, Rust, Go, CLI utils)
8. Install Docker
9. Configure KVM
10. Apply desktop profile
11. Install themes
12. Install Neovim
13. Install Brave Browser
14. Generate SSH keys
15. Apply ricing (if `--rice`)
16. Show dashboard
17. Verify installation
18. Display fastfetch/neofetch

### `./install.sh --dry-run`

Sets `DRY_RUN=true`. The sourced functions (`deploy_symlinks`, `setup_*`)
check this flag and log what they _would_ do without executing:

```
DRY RUN: Would install package: neovim
DRY RUN: Would symlink: .zshrc → /home/user/.zshrc
```

### `./install.sh --rollback`

Restores dotfiles from backup. Calls `rollback_symlinks()` from
`scripts/dotfiles/deploy.sh` which reverts to `~/.backup-YYYY-MM-DD/`.

### `./install.sh --debug`

Sets `DEBUG=true`. Individual sourced scripts read this variable to
enable verbose logging (e.g., printing detected variables, skipped packages).

---

## Profiles

### `./install.sh --minimal`

Disables every optional component. Only performs:
- Package installation (system packages)
- Dotfile symlink deployment

Equivalent to:
```bash
./install.sh --no-theme --no-fonts --no-starship --no-zsh \
             --no-dev --no-docker --no-kvm --no-desktop \
             --no-neovim --no-brave --no-ssh
```

### `./install.sh --profile hyprland`

Sets `DESKTOP_PROFILE=hyprland`. Passed to `setup_desktop()` which installs
Hyprland-specific configuration.

### `./install.sh --profile i3`

Sets `DESKTOP_PROFILE=i3`. Passed to `setup_desktop()` for i3wm config.

### `./install.sh --rice`

Runs `shell/rice.sh` after all other steps — applies Gruvbox theme, GTK
settings, and terminal color schemes.

---

## Skip Flags

All individual component toggles:

```bash
--no-theme    --no-fonts    --no-starship    --no-zsh
--no-dev      --no-docker   --no-kvm          --no-desktop
--no-neovim   --no-brave    --no-ssh
```

Combine freely:

```bash
# Only dotfiles + fonts + starship
./install.sh --unattended --no-dev --no-docker --no-kvm \
             --no-desktop --no-theme --no-neovim --no-brave --no-ssh

# Just dev tools (no dotfiles)
./install.sh --unattended --minimal --no-zsh --no-fonts --no-theme \
             --no-starship --no-docker --no-kvm --no-desktop \
             --no-neovim --no-brave --no-ssh
# (--minimal already disables all, so this re-enables nothing)
```

---

## Git Configuration

```bash
# Set both at once
./install.sh --git-name "Jane Doe" --git-email "jane@example.com"

# These are written to ~/.gitconfig by setup_shell() or setup_git()
```

---

## Help

```bash
./install.sh --help
# or
./install.sh -h
```

Prints the full usage text and exits.

---

## Advanced Examples

```bash
# Re-run previous interactive session (no prompts)
./install.sh --repeat --offline --force

# CI: headless with docker + neovim only
./install.sh --unattended --minimal --no-docker --no-neovim
# Actually, --minimal disables all; to run only docker + neovim:
./install.sh --unattended \
  --no-theme --no-fonts --no-starship --no-zsh \
  --no-dev --no-kvm --no-desktop \
  --no-brave --no-ssh

# Air-gapped server
./install.sh --setup --offline

# Desktop workstation with Hyprland
./install.sh --unattended --profile hyprland --rice
```
