# RINNA Dotfiles — Autonomous Workstation Deployment System

Automated Linux dotfiles bootstrap framework. Installs and configures an entire workstation with a single command.

```bash
./install.sh --unattended
```

> 📖 **Full documentation:** [docs/README.md](docs/README.md) — or browse individual guides below.

## Quick Start

```bash
git clone https://github.com/larvenejafemcoder/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

## Structure

→ See [docs/INSTALLATION.md](docs/INSTALLATION.md) for a line-by-line breakdown of every file's purpose.

```
.dotfiles/
├── install.sh                        # Main entry point / orchestrator
├── scripts/
│   ├── core/
│   │   ├── colors.sh                 # ANSI color definitions
│   │   ├── ui.sh                     # ASCII headers, progress bars, spinners, dashboard
│   │   ├── logging.sh                # File-based structured logging
│   │   ├── utils.sh                  # Symlink manager, backup, idempotency helpers
│   │   └── detect.sh                 # Distribution, hardware, environment detection
│   ├── pkg/
│   │   └── manager.sh                # Unified package manager (apt/pacman/dnf/zypper + AUR/Flatpak/Cargo/Pip/Go)
│   ├── dotfiles/
│   │   └── deploy.sh                 # Stow-based symlink deployment with rollback
│   ├── setup/
│   │   ├── shell.sh                  # Zsh + Oh My Zsh + Powerlevel10k + Starship + Fish
│   │   ├── dev.sh                    # Git, Node/Bun, Rust, Go, Python, SSH keys
│   │   ├── fonts.sh                  # Meslo Nerd Font + JetBrains Mono
│   │   ├── docker.sh                 # Docker + Docker Compose
│   │   ├── kvm.sh                    # KVM/QEMU + libvirt + virt-manager
│   │   ├── desktop.sh                # Hyprland / i3 deployment profiles
│   │   ├── themes.sh                 # Catppuccin + Tahoe + WhiteSur
│   │   ├── neovim.sh                 # Neovim + Lazy plugin manager + Catppuccin
│   │   ├── brave.sh                  # Brave Browser (repo + flatpak fallback)
│   │   └── ssh.sh                    # Ed25519/RSA SSH keys + GPG key
│   └── verify/
│       └── verify.sh                 # Automated verification + report generation
├── config/
│   └── packages/                     # Per-distro package manifests
│       ├── arch.txt
│       ├── ubuntu.txt
│       ├── debian.txt
│       ├── fedora.txt
│       ├── opensuse.txt
│       ├── dev-packages.txt
│       └── flatpak.txt
├── stow/                             # Config files (GNU Stow compatible)
│   ├── alacritty/
│   ├── bash/
│   ├── fastfetch/
│   ├── fish/
│   ├── kitty/
│   ├── neofetch/
│   ├── starship/
│   └── zsh/
├── shell/                            # Legacy shell scripts (rice.sh, etc.)
├── fonts/                            # Font files + installers
├── themes/                           # GTK themes (Tahoe, WhiteSur)
├── gnome-terminal/                   # GNOME Terminal dconf backup
├── .env.example                      # Environment variable template
└── LICENSE                           # MIT
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Overview & Quick Start](docs/README.md) | Landing page, features, project structure, table of contents |
| [Installation (line-by-line)](docs/INSTALLATION.md) | Every variable, function, and control flow in `install.sh` |
| [Architecture](docs/ARCHITECTURE.md) | Flowcharts, state machines, module deps, exit codes, data flow |
| [Commands](docs/COMMANDS.md) | Every flag and subcommand with interactive TUI walkthroughs |
| [Configuration](docs/CONFIGURATION.md) | Config file schema, `.env` format, profiles, package lists |
| [Development](docs/DEVELOPMENT.md) | Coding standards, adding tools/dotfiles, testing, CI/CD, release |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Error matrix, recovery, log locations, debug checklist |
| [Examples](docs/EXAMPLES.md) | Fresh Ubuntu, air-gapped, Arch+Hyprland, CI, multi-machine sync |
| [API Reference](docs/API.md) | Exit codes, log format, programmatic usage, dotfile database |
| [Security](docs/SECURITY.md) | Privilege model, download verification, audit trail |
| [FAQ](docs/FAQ.md) | Top 20 questions |
| [Glossary](docs/GLOSSARY.md) | Terminology reference (TUI, stow, idempotent, XDG, etc.) |

---

## Usage

```bash
./install.sh [OPTIONS]
```

→ See [docs/COMMANDS.md](docs/COMMANDS.md) for detailed usage with TUI screenshots.

### Interactive Modes

| Option | Description |
|--------|-------------|
| `--setup` / `--interactive` | Full interactive menu (dotfiles + tools selection) |
| `--dotfiles-only` | Interactive dotfile selection only |
| `--tools-only` | Interactive dev tools selection only |
| `--repeat` | Re-apply last saved selections |
| `--offline` | Skip all downloads (symlinks only) |
| `--tui` | Rich Python Textual TUI |

### Automated Modes

| Option | Description |
|--------|-------------|
| `--unattended` | Fully automated, no prompts |
| `--dry-run` | Simulate without making changes |
| `--rollback` | Roll back a previous deployment |
| `--debug` | Enable verbose debug output |

### Profiles

| Option | Description |
|--------|-------------|
| `--minimal` | Config symlinks only (skip packages/fonts/themes) |
| `--profile hyprland` | Deploy Hyprland desktop environment |
| `--profile i3` | Deploy i3 desktop environment |
| `--rice` | Also run Gruvbox ricing script (themes, icons, extensions, wallpaper) |

### Skip Flags

| Option | Description |
|--------|-------------|
| `--no-theme` | Skip theme installation |
| `--no-fonts` | Skip font installation |
| `--no-starship` | Skip Starship prompt |
| `--no-zsh` | Skip Zsh/Oh My Zsh |
| `--no-dev` | Skip developer tools |
| `--no-docker` | Skip Docker setup |
| `--no-kvm` | Skip KVM/QEMU setup |
| `--no-desktop` | Skip desktop environment |
| `--no-neovim` | Skip Neovim setup |
| `--no-brave` | Skip Brave browser |
| `--no-ssh` | Skip SSH key generation |

### Git Configuration

```bash
./install.sh --git-name "Your Name" --git-email "you@email.com"
```

Or set environment variables:

```bash
export GIT_USERNAME="Your Name"
export GIT_EMAIL="you@email.com"
./install.sh
```

Or create a `.env` file:

```bash
DOTFILES_GIT_USERNAME="Your Name"
DOTFILES_GIT_EMAIL="you@email.com"
DOTFILES_DESKTOP_PROFILE="hyprland"
```

→ See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for all configuration options.

## Requirements

| Distro | Command |
|--------|---------|
| **Arch** | `sudo pacman -S zsh curl git stow dconf unzip` |
| **Debian/Ubuntu** | `sudo apt install zsh curl git stow dconf-cli unzip` |
| **Fedora** | `sudo dnf install zsh curl git stow dconf unzip` |
| **openSUSE** | `sudo zypper install zsh curl git stow dconf unzip` |

→ Also requires **dialog** or **whiptail** for interactive mode; **Python 3.10+** for `--tui`.

---

## Phases

| Phase | Description |
|-------|-------------|
| 1 | ASCII boot sequence with animated loading |
| 2 | Environment detection (distro, hardware, summary table) |
| 3 | Package installation via distro-agnostic manager |
| 4 | Dotfile deployment via GNU Stow with automatic backup |
| 5 | Developer environment (Git, Node, Rust, Go, Python, Docker, KVM) |
| 6 | Live visual deployment dashboard |
| 7 | Automated verification + final report + ASCII banner |

→ See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for Mermaid flowcharts and data flow diagrams.

---

## Architecture

- **Modular** — Each subsystem is an independent shell script under `scripts/`
- **Idempotent** — Safe to run multiple times; checks before installing
- **Portable** — Supports Ubuntu, Debian, Arch, Fedora, openSUSE
- **Resilient** — Automatic backups, dry-run mode, full rollback support
- **Logged** — Full audit trail at `~/.local/share/dotfiles/install.log`

→ See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | [docs/SECURITY.md](docs/SECURITY.md) | [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)

---

## License

MIT — See [LICENSE](LICENSE)
