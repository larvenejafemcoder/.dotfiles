# Configuration

> **Documentation version:** 2.0.0

---

## Locations

| Path | Purpose |
|------|---------|
| `~/.config/dotfiles-setup/` | Root config directory |
| `~/.config/dotfiles-setup/selections.cfg` | Saved interactive selections |
| `~/.config/dotfiles-setup/history.log` | Append-only install history |
| `~/.config/dotfiles-setup/install-*.log` | Per-run detailed logs |
| `~/.config/dotfiles-setup/install-latest.log` | Symlink to most recent log |
| `~/.config/dotfiles-setup/backups/YYYYMMDD-HHMMSS/` | Pre-overwrite dotfile backups |
| `~/.cache/dotfiles-setup/` | Downloaded assets (tarballs, installers) |
| `$DOTFILES_DIR/.env` | Optional Git/desktop environment overrides |

---

## `selections.cfg` — Format

Simple INI-style format with section headers:

```ini
[dotfiles]
".zshrc" ".bashrc" ".tmux.conf" ".config/alacritty" ".config/starship.toml"

[tools]
"nodejs" "rust" "go" "starship" "neovim" "docker" "cli"

[meta]
last_run=2026-06-13 14:30:22
profile=default
```

- Values are space-separated quoted strings as returned by whiptail
- The `[meta]` section is written by `interactive_setup()`
- Read by `--repeat` mode (not yet implemented — currently `--repeat` is
  reserved for future silent re-apply)

---

## `history.log` — Format

```
2026-06-13 14:30 | dotfiles: 4 files
2026-06-13 14:31 | tools: nodejs rust starship neovim cli
2026-06-13 15:00 | dotfiles: 6 files
```

Append-only. Each entry records the date, category, and what was installed.

---

## `install-*.log` — Format

```
14:30:22 | INFO   Starting interactive setup
14:30:25 | OK     Linked .zshrc → /home/user/.zshrc
14:30:25 | OK     Linked .tmux.conf → /home/user/.tmux.conf
14:30:28 | INFO   Installing: starship
14:30:35 | OK     Installed: starship
```

Timestamps are `HH:MM:SS`. Levels: `INFO`, `OK`, `WARN`, `ERROR`.

---

## `.env` — Environment File

Location: `$DOTFILES_DIR/.env` (not created by default — copy from
`.env.example`)

```bash
# Dotfiles Environment Configuration

DOTFILES_GIT_USERNAME="Your Name"
DOTFILES_GIT_EMAIL="your@email.com"

# Desktop profile: "hyprland", "i3", or leave empty for auto-detect
# DOTFILES_DESKTOP_PROFILE="hyprland"
```

Variables are `source`d with `set -a` (auto-export) so they're available to
all sourced scripts. The `DOTFILES_GIT_*` prefix avoids conflicts with system
`GIT_*` variables.

Loaded by `import_env_config()` during `main()`, after `parse_args()` —
meaning CLI flags override `.env` values.

---

## Profile System

Profiles set the `DESKTOP_PROFILE` variable, used by `setup_desktop()`.

| Profile | Meaning |
|---------|---------|
| `default` | Auto-detect based on running DE/WM |
| `hyprland` | Hyprland Wayland compositor |
| `i3` | i3 window manager (X11) |
| (custom) | Passed through; `setup_desktop()` can handle arbitrary names |

Set via `--profile <name>` or `DOTFILES_DESKTOP_PROFILE` in `.env`.

---

## Environment Variable Overrides

| Variable | Effect | Example |
|----------|--------|---------|
| `DOTFILES_DIR` | Override repo root | `DOTFILES_DIR=/custom/path ./install.sh` |
| `XDG_CONFIG_HOME` | Config directory base | `XDG_CONFIG_HOME=/mnt/config ./install.sh` |
| `GIT_USERNAME` | Git user name | Overrides `--git-name` |
| `GIT_EMAIL` | Git email | Overrides `--git-email` |

---

## Package Lists

Located in `config/packages/*.txt`, named by distro:

| File | Used when |
|------|-----------|
| `config/packages/ubuntu.txt` | DISTRO=ubuntu |
| `config/packages/debian.txt` | DISTRO=debian |
| `config/packages/arch.txt` | DISTRO=arch |
| `config/packages/fedora.txt` | DISTRO=fedora |
| `config/packages/opensuse.txt` | DISTRO=opensuse |
| `config/packages/dev-packages.txt` | Common development packages |

Each file contains one package name per line. Loaded by
`pkg_install_from_file()` in `scripts/pkg/manager.sh`.

---

## Backup Retention

Backups are stored in `$SETUP_BACKUP_DIR` with the full directory tree
preserved:

```
~/.config/dotfiles-setup/backups/20260613-143022/
├── home/
│   └── user/
│       ├── .zshrc
│       ├── .bashrc
│       └── .config/
│           └── alacritty/
│               ├── alacritty.toml
│               └── keybindings.toml
```

There is **no automatic cleanup** of old backups. To purge:

```bash
rm -rf ~/.config/dotfiles-setup/backups/*
```
