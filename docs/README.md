# Dotfiles & Dev Tools Setup

> **Version:** 2.0.0 | **License:** MIT | **Shell:** Bash 5.0+ | **TUI:** Dialog / Whiptail / Textual

A cross-distro dotfiles manager and interactive dev-environment bootstrap with dual
interfaces: a **dialog/whiptail TUI** for quick interactive selection and a **Textual
Python TUI** for a richer terminal experience.

```bash
git clone https://github.com/your-org/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh --setup
```

[![Bash](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![cross-distro](https://img.shields.io/badge/distro-arch%20%7C%20ubuntu%20%7C%20fedora%20%7C%20opensuse-blue)

---

## Features

- **Dual TUI** — Dialog/whiptail checklist for dotfiles & tools; Textual-based rich TUI
- **Cross-distro** — Auto-detects apt, dnf, pacman, zypper
- **Idempotent** — Safe to re-run; skips already-linked dotfiles, backs up before overwriting
- **Offline mode** — `--offline` skips all downloads, only uses cached packages
- **Repeat mode** — `--repeat` re-applies last selections without re-prompting
- **Profiles** — `--minimal`, `--profile hyprland`, `--profile i3`, `--rice`
- **GNU Stow** — Manages symlinks for 8 stow packages (zsh, bash, alacritty, kitty, fish, starship, fastfetch, neofetch)
- **Dev tools** — Node.js (nvm), Rust (rustup), Go, Starship, Neovim, Docker, CLI utils (eza, bat, fzf, ripgrep, fd, lazygit, jq, httpie, zoxide)

---

## Quick Start

```bash
# Interactive setup (full menu)
./install.sh --setup

# Dotfiles only
./install.sh --dotfiles-only

# Dev tools only
./install.sh --tools-only

# Headless full install
./install.sh --unattended

# Re-run saved selections
./install.sh --repeat

# Textual Python TUI
./install.sh --tui
```

---

## Table of Contents

| Document | Description |
|----------|-------------|
| [Installation](INSTALLATION.md) | Line-by-line script breakdown, variable/function reference |
| [Architecture](ARCHITECTURE.md) | Flowcharts, state machines, data flow, exit codes |
| [Commands](COMMANDS.md) | Every flag and subcommand with examples |
| [Configuration](CONFIGURATION.md) | Config file schema, environment variables, profiles |
| [Development](DEVELOPMENT.md) | Contributor guide, testing, adding tools/dotfiles |
| [Troubleshooting](TROUBLESHOOTING.md) | Error matrix, recovery, log locations |
| [Examples](EXAMPLES.md) | Real-world scenarios (fresh install, air-gapped, CI) |
| [API Reference](API.md) | Exit codes, log format, programmatic usage |
| [Security](SECURITY.md) | Privilege model, audit, supply-chain mitigations |
| [FAQ](FAQ.md) | Top 20 frequently asked questions |
| [Glossary](GLOSSARY.md) | Terminology reference |

---

## Minimum Requirements

- **OS:** Linux (Arch, Ubuntu/Debian, Fedora, openSUSE) or macOS (partial)
- **Shell:** Bash 5.0+
- **Python:** 3.10+ (only for `--tui` mode)
- **Dialog** or **Whiptail** (only for `--setup` interactive mode)
- **Git,** **Curl,** **Stow** (recommended)

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  install.sh  (entry point — CLI arg parser & orchestration)     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─ Automated ───────────────────────────────────────────────┐  │
│  │  --unattended  →  detect → packages → dotfiles → tools   │  │
│  │                   shell → fonts → docker → kvm → desktop  │  │
│  │                   themes → neovim → brave → ssh → verify  │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌─ Interactive ─────────────────────────────────────────────┐  │
│  │  --setup  →  menu [dotfiles | tools | exit]               │  │
│  │  --dotfiles-only  →  checklist → symlink → stow          │  │
│  │  --tools-only     →  checklist → install dispatch         │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌─ TUI ──────────────────────────────────────────────────────┐  │
│  │  --tui  →  tui.sh  →  Python venv  →  main.py (Textual)   │  │
│  └───────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  scripts/core/  →  colors, detect, logging, ui, utils          │
│  scripts/pkg/   →  manager.sh (apt/dnf/pacman/zypper wrapper)  │
│  scripts/setup/ →  individual component installers             │
│  scripts/dotfiles/ →  deploy.sh (stow + backup)                │
│  modules/       →  Python TUI screens (Textual)                │
│  stow/          →  GNU Stow-managed dotfile packages           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
dotfiles/
├── install.sh              # Main entry point (757 lines)
├── tui.sh                  # Python TUI bootstrap (55 lines)
├── main.py                 # Textual TUI application
├── modules/                # Python TUI modules
├── scripts/
│   ├── core/               # Shared libraries (colors, detect, logging, ui, utils)
│   ├── pkg/                # Package manager abstraction
│   ├── setup/              # Component installers (dev, fonts, docker, kvm, etc.)
│   ├── dotfiles/           # Deploy/rollback logic
│   └── verify/             # Post-install verification
├── stow/                   # GNU Stow-managed dotfile packages
├── config/packages/        # Per-distro package lists (*.txt)
├── bootstrap*.sh           # Legacy bootstrappers
└── setup.sh                # Standalone interactive script (deprecated)
```

---

## License

MIT — see [LICENSE](../LICENSE).
