# API Reference

> **Documentation version:** 2.0.0

---

## Exit Codes

| Code | Constant | Meaning | Raised by |
|------|----------|---------|-----------|
| 0 | `EXIT_SUCCESS` | Success | All normal exit paths |
| 1 | `EXIT_FAILURE` | General error | Multiple sources |
| 1 | — | Unknown CLI flag | `parse_args()` |
| 1 | — | No TUI backend | `tui_init()` |
| 1 | — | `set -e` command failure | Any failing command |
| 1 | — | `set -u` unset variable | Any unset reference |
| 2 | — | Builtin error | Bash builtins |
| 126 | — | Command not executable | Bash |
| 127 | — | Command not found | Bash |
| 128 | — | Invalid exit argument | Bash |
| 130 | — | SIGINT (Ctrl+C) | Whiptail/dialog |
| 137 | — | SIGKILL (9) | System |
| 255 | — | SIGTERM (15) / exit out of range | System / Bash |

### Detecting exit codes programmatically

```bash
./install.sh --setup
case $? in
    0)   echo "Success" ;;
    1)   echo "Error: check log" ;;
    130) echo "Cancelled by user" ;;
    *)   echo "Unexpected exit: $?" ;;
esac
```

---

## Log File Format

### Interactive logs (`install-*.log`)

```
HH:MM:SS | LEVEL  message
```

Where `LEVEL` is one of:

| Level | Prefix | Color | Meaning |
|-------|--------|-------|---------|
| `INFO` | `[INFO]` | Blue | Informational message |
| `OK` | `[ OK ]` | Green | Successful operation |
| `WARN` | `[WARN]` | Yellow | Non-fatal issue |
| `ERROR` | `[ERR!]` | Red | Failed operation |

Example:

```
14:30:22 | INFO   Starting interactive setup
14:30:22 | INFO   Detected package manager: apt
14:30:25 | OK     Linked .zshrc → /home/user/.zshrc
14:30:28 | WARN   Offline — skipping: nodejs
14:30:28 | ERROR  Failed: neovim
```

### Parsing logs

```bash
# Get all errors from latest run
grep ERROR ~/.config/dotfiles-setup/install-latest.log

# Get all successfully installed items
grep OK ~/.config/dotfiles-setup/install-latest.log

# Count by level
grep -c 'INFO\|OK\|WARN\|ERROR' ~/.config/dotfiles-setup/install-latest.log
```

---

## Config File Format (`selections.cfg`)

```ini
[dotfiles]
".zshrc" ".bashrc" ".config/alacritty" ".config/starship.toml"

[tools]
"nodejs" "rust" "starship" "neovim" "cli"

[meta]
last_run=2026-06-13 14:30:22
profile=default
```

### Parsing programmatically

```bash
# Get selected dotfiles
grep '^\[dotfiles\]' -A1 ~/.config/dotfiles-setup/selections.cfg | tail -1

# Get selected tools
grep '^\[tools\]' -A1 ~/.config/dotfiles-setup/selections.cfg | tail -1

# Simple INI parser in bash
parse_ini() {
    local section="$1" key="$2"
    awk -F= -v s="$section" -v k="$key" '
        /^\[/{ sec=gensub(/^\[(.*)\]$/, "\\1", 1, $0) }
        sec==s && $1==k { print $2 }
    ' "$3"
}
```

---

## History Log Format (`history.log`)

```
YYYY-MM-DD HH:MM | category: details
```

| Field | Example |
|-------|---------|
| Date | `2026-06-13` |
| Time | `14:30` |
| Category | `dotfiles` or `tools` |
| Details | `4 files` or `nodejs rust starship neovim cli` |

---

## Environment Variables for Programmatic Use

| Variable | Set by | Purpose | Example |
|----------|--------|---------|---------|
| `DOTFILES_DIR` | `install.sh` | Repo root path | `/home/user/.dotfiles` |
| `DRY_RUN` | `--dry-run` | If `true`, skip actual exec | `DRY_RUN=true` |
| `DEBUG` | `--debug` | If `true`, verbose output | `DEBUG=1` |
| `PKG_MANAGER` | `detect_package_manager()` | Auto-detected PM | `apt` |
| `DISTRO` | `detect_environment()` | Auto-detected OS | `ubuntu` |
| `OFFLINE` | `--offline` | If `1`, skip downloads | `OFFLINE=1` |

### Calling from other scripts

```bash
#!/usr/bin/env bash
# Programmatic invocation of the dotfiles installer

export DOTFILES_DIR="/opt/dotfiles"
export DRY_RUN=true
export OFFLINE=1

# Source key functions without running main()
source "$DOTFILES_DIR/install.sh"

# Use dotfile resolution
source_path=$(dotfile_source ".zshrc")
echo "Source: $source_path"
```

---

## Dotfile Database

Each tool in the interactive checklist has associated metadata:

| Key | Tag | Detection command | Install method |
|-----|-----|-------------------|---------------|
| nodejs | Languages | `command -v node` | nvm |
| rust | Languages | `command -v rustc` | rustup |
| go | Languages | `command -v go` | Download tarball |
| starship | Terminal | `command -v starship` | Install script |
| tmux | Terminal | `command -v tmux` | Package manager |
| neovim | Editors | `command -v nvim` | PPA + package |
| docker | DevOps | `command -v docker` | get.docker.com |
| eza | Utilities | `command -v eza` | Package manager |
| bat | Utilities | `command -v bat` | Package manager |
| fzf | Utilities | `command -v fzf` | Package manager |
| ripgrep | Utilities | `command -v rg` | Package manager |
| fd | Utilities | `command -v fd` | Package manager |
| lazygit | Utilities | `command -v lazygit` | Package manager |
| jq | Utilities | `command -v jq` | Package manager |
| httpie | Utilities | `command -v http` | Package manager |
| zoxide | Utilities | `command -v zoxide` | Install script |

---

## Signals

The script does **not** install custom signal handlers. Default Bash behavior:

| Signal | Number | Default | Effect in script |
|--------|--------|---------|-----------------|
| SIGINT | 2 | Terminate | Script exits, no cleanup |
| SIGTERM | 15 | Terminate | Script exits, no cleanup |
| SIGHUP | 1 | Terminate | Script exits if terminal closes |
| SIGPIPE | 13 | Ignore | Safe with `set -o pipefail` |

To add cleanup:

```bash
trap 'rm -f "$SETUP_SUMMARY"; echo "Interrupted" >&2' INT TERM
```
