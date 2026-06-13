# Installation Guide — Line-by-Line Breakdown

> **Applies to:** `install.sh` (770 lines)
> **Last updated:** 2026-06-13

This document explains every section of the setup script. Each numbered section
corresponds to a logical block in `install.sh`.

---

## 1. Shebang and Safety Options (Lines 1-5)

```bash
#!/usr/bin/env bash
set -euo pipefail
```

| Directive | Effect |
|-----------|--------|
| `#!/usr/bin/env bash` | Locates `bash` via `PATH` instead of hardcoding `/bin/bash` — portable across systems that install bash in non-standard locations (e.g., NixOS, Homebrew on macOS). |
| `set -e` | **Exit on error.** If any command returns non-zero, the script aborts immediately. Prevents silent failures from propagating. ⚠ _Disabled inside `||` conditions and `if` tests._ |
| `set -u` | **Treat unset variables as errors.** Accessing `$UNDEFINED_VAR` triggers exit — catches typos early. |
| `set -o pipefail` | **Pipeline failures are fatal.** If any stage of `cmd1 | cmd2` fails, the whole pipeline returns non-zero (instead of only the last stage). |

> [!WARNING]
> `set -e` can be surprising: if a function you call returns 1 for a legitimate
> reason (e.g., `grep` found no match), the whole script exits. The pattern
> `cmd || true` is used extensively to allow expected failures.

---

## 2. Environment Setup (Lines 7-8)

```bash
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR
```

- `BASH_SOURCE[0]` — path to the currently executing script (`install.sh`)
- `$(dirname ...)` — strips the filename, leaving the directory component
- `cd ... && pwd` — resolves symlinks and gives an absolute path
- `export` — makes `$DOTFILES_DIR` available to sourced library scripts

> [!NOTE]
> This pattern works reliably even when the script is invoked via symlink or
> from `$PATH`.

---

## 3. Library Sources (Lines 10-26)

```bash
for lib in "$DOTFILES_DIR/scripts/core"/*.sh; do source "$lib"; done
source "$DOTFILES_DIR/scripts/pkg/manager.sh"
source "$DOTFILES_DIR/scripts/dotfiles/deploy.sh"
source "$DOTFILES_DIR/scripts/setup/shell.sh"
source "$DOTFILES_DIR/scripts/setup/dev.sh"
source "$DOTFILES_DIR/scripts/setup/fonts.sh"
source "$DOTFILES_DIR/scripts/setup/docker.sh"
source "$DOTFILES_DIR/scripts/setup/kvm.sh"
source "$DOTFILES_DIR/scripts/setup/desktop.sh"
source "$DOTFILES_DIR/scripts/setup/themes.sh"
source "$DOTFILES_DIR/scripts/setup/neovim.sh"
source "$DOTFILES_DIR/scripts/setup/brave.sh"
source "$DOTFILES_DIR/scripts/setup/ssh.sh"
source "$DOTFILES_DIR/scripts/verify/verify.sh"
```

| Source file | Provides |
|-------------|----------|
| `scripts/core/*.sh` | `colors.sh` (ANSI vars), `detect.sh` (OS/distro detection), `logging.sh`, `ui.sh` (draw_boot_screen, draw_dashboard), `utils.sh` |
| `scripts/pkg/manager.sh` | `detect_package_manager()`, `pkg_update()`, `pkg_install_from_file()` |
| `scripts/dotfiles/deploy.sh` | `init_deploy()`, `deploy_symlinks()`, `rollback_symlinks()` |
| `scripts/setup/shell.sh` | `setup_shell()` — Zsh + Starship |
| `scripts/setup/dev.sh` | `setup_development()` — Node, Rust, Go, CLI tools |
| `scripts/setup/fonts.sh` | `setup_fonts()` — Meslo Nerd Font |
| `scripts/setup/docker.sh` | `setup_docker()` |
| `scripts/setup/kvm.sh` | `setup_kvm()` |
| `scripts/setup/desktop.sh` | `setup_desktop()` — Profile-based desktop config |
| `scripts/setup/themes.sh` | `setup_themes()` |
| `scripts/setup/neovim.sh` | `setup_neovim()` |
| `scripts/setup/brave.sh` | `setup_brave()` |
| `scripts/setup/ssh.sh` | `setup_ssh_keys()` |
| `scripts/verify/verify.sh` | `run_verification()` |

> [!IMPORTANT]
> Source order matters: `core/*` provides the color/logging primitives that all
> subsequent sourced scripts depend on.

---

## 4. Global Flag Variables (Lines 28-55)

### Automated Install Flags (Lines 28-31)

```bash
DRY_RUN=false        # --dry-run: simulate without changes
UNATTENDED=false     # --unattended: no prompts
ROLLBACK_MODE=false  # --rollback: undo last deployment
DEBUG=false          # --debug: verbose output
```

### Component Toggles (Lines 34-46)

```bash
INSTALL_THEME=true   INSTALL_FONTS=true    INSTALL_STARSHIP=true
INSTALL_ZSH=true     INSTALL_RICE=false    INSTALL_DEV=true
INSTALL_DOCKER=true  INSTALL_KVM=true      INSTALL_DESKTOP=true
INSTALL_NEOVIM=true  INSTALL_BRAVE=true    INSTALL_SSH=true
MINIMAL=false        DESKTOP_PROFILE="default"
```

All individual components are `true` by default. `MINIMAL=true` (set by
`--minimal`) disables every optional component, leaving only dotfile symlinks.

### Interactive Mode Flags (Lines 50-55)

```bash
SETUP_MODE=false     # --setup / --interactive
DOTFILES_ONLY=false  # --dotfiles-only
TOOLS_ONLY=false     # --tools-only
REPEAT=false          # --repeat (re-apply saved selections)
OFFLINE=false         # --offline (skip downloads)
FORCE=false           # --force (overwrite without confirm)
```

> [!NOTE]
> Capitalization convention: uppercase globals (`DOTFILES_DIR`, `PKG_MANAGER`)
> are shared across sourced scripts; lowercase/descriptive (`SETUP_MODE`) are
> local to `install.sh`.

---

## 5. Config Directory Variables (Lines 58-63)

```bash
SETUP_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-setup"
SETUP_CONFIG_FILE="$SETUP_CONFIG_DIR/selections.cfg"
SETUP_LOG_FILE="$SETUP_CONFIG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
SETUP_BACKUP_DIR="$SETUP_CONFIG_DIR/backups/$(date +%Y%m%d-%H%M%S)"
SETUP_HISTORY="$SETUP_CONFIG_DIR/history.log"
SETUP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-setup"
```

| Variable | Purpose | Example value |
|----------|---------|---------------|
| `SETUP_CONFIG_DIR` | Root config directory | `~/.config/dotfiles-setup` |
| `SETUP_CONFIG_FILE` | Saved selections (INI-like) | `~/.config/dotfiles-setup/selections.cfg` |
| `SETUP_LOG_FILE` | Per-run log with timestamp | `.../install-20260613-143022.log` |
| `SETUP_BACKUP_DIR` | Pre-overwrite backups | `.../backups/20260613-143022` |
| `SETUP_HISTORY` | Append-only history log | `.../history.log` |
| `SETUP_CACHE` | Downloaded tarballs, etc. | `~/.cache/dotfiles-setup` |

> [!TIP]
> Backups preserve directory structure: `~/.config/alacritty/alacritty.toml` is
> backed up to `$BACKUP_DIR/home/user/.config/alacritty/alacritty.toml`.

---

## 6. Color Variables (Lines 66-70)

```bash
cR="${RED:-'\033[0;31m'}"    # Red
cG="${GREEN:-'\033[0;32m'}"  # Green
cY="${YELLOW:-'\033[1;33m'}" # Yellow (bold)
cB="${BLUE:-'\033[0;34m'}"   # Blue
cC="${CYAN:-'\033[0;36m'}"   # Cyan
cM="${MAGENTA:-'\033[0;35m'}"# Magenta
cN="${RESET:-'\033[0m'}"     # Reset
cD="${DIM:-'\033[2m'}"       # Dim
BOLD="${BOLD:-'\033[1m'}"    # Bold
```

The `:-` fallback syntax ensures colors work even if `scripts/core/colors.sh`
failed to load. The `c` prefix distinguishes these from the exported uppercase
variables (`RED`, `GREEN`, etc.) in `colors.sh`.

**ANSI escape primer:**

| Code | Effect |
|------|--------|
| `\033[0m` | Reset all attributes |
| `\033[1m` | Bold / bright |
| `\033[2m` | Dim |
| `\033[0;31m` | Normal-intensity red |
| `\033[1;33m` | Bold (bright) yellow |

---

## 7. Interactive Logging (Lines 73-77)

```bash
setup_log()   { echo -e "$(date '+%H:%M:%S') | $*" | tee -a "$SETUP_LOG_FILE" >&2; }
setup_info()  { setup_log "${cB}INFO${cN}  $*"; }
setup_ok()    { setup_log "${cG}OK${cN}    $*"; }
setup_warn()  { setup_log "${cY}WARN${cN}  $*"; }
setup_err()   { setup_log "${cR}ERROR${cN} $*"; }
```

- Every message is timestamped and **tee'd** to both the log file and stderr
- Stderr (`>&2`) preserves the ability to pipe stdout for programmatic use
- Four log levels: `INFO` (blue), `OK` (green), `WARN` (yellow), `ERROR` (red)

---

## 8. TUI Backend Selection (Lines 81-95)

```bash
TUI_BE=""
tui_init() {
    if command -v dialog &>/dev/null; then TUI_BE="dialog"
    elif command -v whiptail &>/dev/null; then TUI_BE="whiptail"
    else
        echo -e "${cY}Warning: neither dialog nor whiptail found.${cN}"
        return 1
    fi
    return 0
}
```

**Priority:** `dialog` > `whiptail`. Both expose the same interface (checklist,
menu, msgbox, yesno), though dialog supports more widgets and color themes.

### TUI Wrappers

```bash
tui_menu()      { local t="$1" m="$2"; shift 2; $TUI_BE --clear --backtitle "Dotfiles Setup" --title "$t" --menu "$m" 0 0 0 "$@" 3>&1 1>&2 2>&3; }
tui_checklist() { local t="$1" m="$2"; shift 2; $TUI_BE --clear --backtitle "Dotfiles Setup" --title "$t" --checklist "$m" 0 0 0 "$@" 3>&1 1>&2 2>&3; }
tui_msgbox()    { $TUI_BE --clear --backtitle "Dotfiles Setup" --title "$1" --msgbox "$2" 0 0 3>&1 1>&2 2>&3; }
tui_yesno()     { $TUI_BE --clear --backtitle "Dotfiles Setup" --title "$1" --yesno "$2" 0 0 3>&1 1>&2 2>&3; }
```

The `3>&1 1>&2 2>&3` redirect swaps stdout and stderr: dialog/whiptail output
(selected items) goes to stdout, while their ncurses rendering goes to stderr.
The calling code captures stdout via `$()`.

| Params | Meaning |
|--------|---------|
| `0 0 0` | Height, width, menu-height (auto) |
| `--clear` | Redraw after each screen |
| `--backtitle` | Persistent footer text |

---

## 9. Spinner and `setup_run` (Lines 98-114)

```bash
setup_spinner() {
    local pid=$1 msg="${2:-Working...}" spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${cC}%s${cN} %s" "${spin:$i:1}" "$msg"
        i=$(( (i+1) % ${#spin} ))
        sleep 0.1
    done
    printf "\r${cG}✓${cN} %-60s\n" "$msg"
}

setup_run() {
    local msg="$1" rc; shift
    ("$@" 2>&1 | tee -a "$SETUP_LOG_FILE" >/dev/null) &
    setup_spinner $! "$msg"
    wait $!; rc=$?
    return $rc
}
```

- `setup_spinner` polls `kill -0 $pid` every 100ms, cycling through braille
  characters (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`)
- `setup_run` backgrounds the command, attaches the spinner, then waits for
  completion and returns the exit code
- Stdout/stderr of the backgrounded command are **silently** logged (redirected
  to `/dev/null` for terminal display, appended to log)

---

## 10. Dotfiles Catalogue (Lines 117-129)

```bash
DOTFILES_ITEMS=(
    ".zshrc"            "Zsh configuration"             off
    ".bashrc"           "Bash configuration"            off
    ".vimrc"            "Vim configuration"             off
    ".tmux.conf"        "Tmux configuration"            off
    ".gitconfig"        "Git configuration"             off
    ".config/alacritty" "Alacritty terminal config"     off
    ".config/nvim"      "Neovim configuration"          off
    ".config/i3"        "I3 window manager config"      off
    ".config/kitty"     "Kitty terminal config"         off
    ".config/starship.toml" "Starship prompt config"    off
    ".config/fish"      "Fish shell config"             off
)
```

Triplet format: `(name description default_state)`. Only entries whose source
file exists in the repo are shown in the checklist (filtered by `dotfile_source()`).

---

## 11. `dotfile_source()` — Source Resolution (Lines 131-158)

```bash
dotfile_source() {
    local name="$1"
    local base="${name##*/}"
    for pkg in "$DOTFILES_DIR/stow/"*/; do
        [ -d "$pkg" ] || continue
        local pkg_name="$(basename "$pkg")"
        if [[ "$name" == ".config/$pkg_name"* ]] || [ -f "$pkg/$base" ]; then
            if [ -e "$pkg/$name" ]; then
                echo "$pkg/$name"
                return 0
            fi
        fi
    done
    [ -f "$DOTFILES_DIR/$name" ]               && { echo "$DOTFILES_DIR/$name"; return 0; }
    [ -f "$DOTFILES_DIR/home/$name" ]          && { echo "$DOTFILES_DIR/home/$name"; return 0; }
    local dir="${name#.}"; dir="${dir%%/*}"
    [ -f "$DOTFILES_DIR/$dir/$name" ]          && { echo "$DOTFILES_DIR/$dir/$name"; return 0; }
    [ -f "$DOTFILES_DIR/shell/$name" ]         && { echo "$DOTFILES_DIR/shell/$name"; return 0; }
    [ -f "$DOTFILES_DIR/git/$name" ]           && { echo "$DOTFILES_DIR/git/$name"; return 0; }
    [ -f "$DOTFILES_DIR/tmux/$name" ]          && { echo "$DOTFILES_DIR/tmux/$name"; return 0; }
    [ -f "$DOTFILES_DIR/terminal/$name" ]      && { echo "$DOTFILES_DIR/terminal/$name"; return 0; }
    [ -f "$DOTFILES_DIR/config/$base" ]        && { echo "$DOTFILES_DIR/config/$base"; return 0; }
    return 1
}
```

**Search order:**
1. **Stow packages** — scans `stow/alacritty/`, `stow/zsh/`, etc. for `$name`
2. **Root** — `$DOTFILES_DIR/$name` (e.g., `.zshrc` at repo root)
3. **home/** — `$DOTFILES_DIR/home/$name`
4. **Named dir** — strips leading dot: `.config/alacritty` → `config/`, checks `config/.config/alacritty`
5. **Known dirs** — `shell/`, `git/`, `tmux/`, `terminal/`, `config/`

> [!TIP]
> `.zshrc` lives in `stow/zsh/`, `.config/alacritty` lives in `stow/alacritty/`.
> The function matches by checking if the stow package directory contains the
> file at the relative path `$name` (preserving the dot prefix).

---

## 12. Backup & Install Functions (Lines 160-182)

### `backup_dotfile()`
```bash
backup_dotfile() {
    local target="$1"
    [ ! -e "$target" ] && return 0
    local bak="$SETUP_BACKUP_DIR/${target#/}"
    mkdir -p "$(dirname "$bak")"
    cp -rL "$target" "$bak" 2>/dev/null
    setup_ok "Backed up: $target"
}
```

- Strips the leading `/` from the absolute path to create a relative backup path
- Uses `cp -rL` (recursive, follow symlinks) to preserve directory structure

### `install_dotfile()`
```bash
install_dotfile() {
    local name="$1" src="$2" target="$3"
    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
        setup_log "  ${cD}✓ $name already linked${cN}"
        echo "  ✓ $name (already linked)" >> "$SETUP_SUMMARY"
        return 0
    fi
    backup_dotfile "$target"
    rm -rf "$target" 2>/dev/null || true
    ln -sf "$src" "$target"
    setup_ok "Linked $name → $target"
    echo "  ✓ $name → $target" >> "$SETUP_SUMMARY"
}
```

**Idempotency check:** If the target is already a symlink pointing at the
correct source, skip. Otherwise: backup → remove → symlink.

---

## 13. `interactive_dotfiles()` (Lines 184-239)

This function:
1. Filters `DOTFILES_ITEMS` to only those whose source exists
2. Shows a TUI checklist with an `__all__` shortcut option
3. Iterates selections, calling `install_dotfile()` for each
4. Offers to run `stow -R` for all stow-managed packages
5. Writes selections to `selections.cfg` and appends to `history.log`

**Checklist output format:** Whiptail returns selected items as a
tab-separated string wrapped in quotes. The `__all__` item is detected
by `grep -q` on the raw output.

---

## 14. Package Manager Detection & Install (Lines 243-254)

```bash
pkg_install_interactive() {
    local pkgs=()
    for p in "$@"; do pkgs+=("$p"); done
    [ ${#pkgs[@]} -eq 0 ] && return 0
    [ "$OFFLINE" = 1 ] && { setup_warn "Offline — skipping: ${pkgs[*]}"; return 0; }
    setup_info "Installing: ${pkgs[*]}"
    sudo_check "package install (${pkgs[*]})"
    $PKG_INSTALL "${pkgs[@]}" 2>&1 | tee -a "$SETUP_LOG_FILE" >/dev/null
    local rc=${PIPESTATUS[0]}
    [ "$rc" -eq 0 ] && setup_ok "Installed: ${pkgs[*]}" || setup_err "Failed: ${pkgs[*]}"
    return $rc
}
```

`PKG_INSTALL` is set by `interactive_setup()` based on the detected package
manager:

| Manager | `PKG_INSTALL` value |
|---------|---------------------|
| apt     | `sudo apt-get install -y -qq` |
| dnf     | `sudo dnf install -y -q` |
| pacman  | `sudo pacman -S --noconfirm --needed` |
| (other) | `sudo apt-get install -y -qq` |

`PIPESTATUS[0]` captures the exit code of the package manager (not `tee`).

---

## 15. Individual Tool Installers (Lines 256-315)

Each follows the same pattern:

```bash
install_TOOL_interactive() {
    # 1. Check if already installed → skip
    command -v tool &>/dev/null && { setup_log "..."; return 0; }
    # 2. Check offline mode
    [ "$OFFLINE" = 1 ] && { echo "..."; return 0; }
    # 3. Install
    setup_run "Installing Tool..." <install-command>
    # 4. Log success
    echo "  ✓ Tool" >> "$SETUP_SUMMARY"
}
```

| Function | Install method |
|----------|---------------|
| `install_nodejs_interactive` | nvm → `nvm install --lts` |
| `install_rust_interactive` | rustup.sh |
| `install_go_interactive` | Download tarball → `/usr/local/go` |
| `install_starship_interactive` | starship.rs install script |
| `install_neovim_interactive` | PPA (apt) or `pkg_install_interactive` |
| `install_docker_interactive` | get.docker.com (apt) or distro package |

---

## 16. `interactive_tools()` (Lines 317-361)

Displays a categorized checklist:
```
Languages:  nodejs, rust, go
Terminal:   starship, tmux
Editors:    neovim
DevOps:     docker
Utilities:  cli (eza, bat, fzf, ripgrep, fd, lazygit, jq, httpie, zoxide)
```

Selected items are dispatched via a `case` statement. The `cli` bundle installs
packages via `pkg_install_interactive` plus zoxide via its install script.

---

## 17. `interactive_setup()` — Main Menu (Lines 365-411)

```
┌──────────────────────────────────┐
│   Dotfiles & Dev Tools — Setup   │
├──────────────────────────────────┤
│ 1. Install / update dotfiles     │
│ 2. Install development tools     │
│ 3. Exit                          │
└──────────────────────────────────┘
```

**Flow:**
1. Create config/backup/cache directories
2. Initialize `TUI_BE` (dialog/whiptail)
3. Detect package manager
4. Show infinite menu until `exit` is chosen
5. Display summary, copy log to `install-latest.log`

---

## 18. `sudo_check()` (Lines 414-418)

```bash
sudo_check() {
    if ! sudo -n true 2>/dev/null; then
        setup_warn "Sudo needed: $*"
        sudo -v
    fi
}
```

- `sudo -n true` tests for a cached credential without prompting
- If expired, `sudo -v` refreshes (prompts once, caches for 5 min by default)

---

## 19. `parse_args()` (Lines 420-518)

A `while` loop consuming `$1` each iteration via `shift`. See
[Commands](COMMANDS.md) for the full flag reference.

Important implementation details:

- `--minimal` disables **all** component toggles at once (sets 10 flags to false)
- `--profile` consumes the next argument: `shift; DESKTOP_PROFILE="$1"`
- `--tui` uses `exec` to replace the shell process with `tui.sh` — no return
- `--help` prints usage and `exit 0`

---

## 20. Status Tracker (Lines 520-528)

```bash
declare -A DEPLOY_STATUS
init_status() {
    DEPLOY_STATUS=( ["Detection"]="pending" ["Packages"]="pending" ... )
}
update_status() { local key="$1" value="$2"; DEPLOY_STATUS["$key"]="$value"; }
```

The `draw_dashboard()` function (from `scripts/core/ui.sh`) renders this assoc
array as a color-coded table:

| State | Color |
|-------|-------|
| pending | Yellow |
| running | Cyan |
| completed | Green |
| skipped | Dim |
| failed | Red |

---

## 21. `import_env_config()` (Lines 531-545)

```bash
import_env_config() {
    local env_file="${DOTFILES_DIR}/.env"
    if [[ -f "$env_file" ]]; then
        set -a
        source "$env_file"
        set +a
    fi
    GIT_USERNAME="${GIT_USERNAME:-${DOTFILES_GIT_USERNAME:-}}"
    GIT_EMAIL="${GIT_EMAIL:-${DOTFILES_GIT_EMAIL:-}}"
    ...
}
```

- `set -a` automatically exports every sourced variable
- `DOTFILES_GIT_*` prefix allows naming `.env` keys without conflicting with
  system variables

---

## 22. `main()` — Orchestrator (Lines 547-755)

### Phase 1: Interactive branching (Lines 550-564)

```bash
if [[ "$SETUP_MODE" == "true" ]]; then
    if [[ "$DOTFILES_ONLY" == "true" ]]; then interactive_dotfiles
    elif [[ "$TOOLS_ONLY" == "true" ]]; then interactive_tools
    else interactive_setup
    fi
    exit 0
fi
```

If `--setup`, `--dotfiles-only`, or `--tools-only` is passed, the script
branches to the interactive path and exits. The automated path never runs.

### Phase 2–7: Automated pipeline (Lines 566–755)

| Phase | Status key | Function |
|-------|-----------|----------|
| 0 — Rollback | — | `rollback_symlinks()` (if `--rollback`) |
| 1 — Boot | — | `draw_boot_screen()` |
| 2 — Detection | `Detection` | `detect_environment()`, `display_summary()` |
| 3 — Packages | `Packages` | `pkg_update()`, `pkg_install_from_file()` |
| 4 — Dotfiles | `Dotfiles` | `deploy_symlinks()` |
| 5 — Components | `Shell`, `Fonts`, etc. | Each `setup_*` function guarded by `INSTALL_*` flag |
| 6 — Dashboard | — | `draw_dashboard()` |
| 7 — Verification | `Verification` | `run_verification()` |
| Final | — | `fastfetch`/`neofetch`, `final_banner()` |

### Component guard pattern

```bash
if [[ "$INSTALL_THING" == "true" ]]; then
    update_status "Thing" "running"
    setup_thing
    update_status "Thing" "completed"
else
    update_status "Thing" "skipped"
fi
```

---

## 23. Exit Codes

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | General error (unset variable, command failure with `set -u`) |
| 1 | `tui_init` failure (no dialog/whiptail) |
| 1 | Unknown CLI flag |
| 130 | SIGINT (Ctrl+C) — inherited from `dialog`/`whiptail` |
| 255 | SIGTERM |

---

## 24. Edge Cases

| Scenario | Behavior |
|----------|----------|
| **First run, no config dir** | Created automatically by `mkdir -p` |
| **Dotfile target is a regular file (not symlink)** | Backed up, then removed, then symlinked |
| **Dotfile target is already the correct symlink** | Skipped (idempotent) |
| **Tool already installed** | Skipped (check via `command -v`) |
| **Package manager not found** | Falls back to `apt` (best-effort) |
| **Network offline + `--offline`** | Skipped with log entry |
| **Network offline, no `--offline`** | Install commands may fail; error is logged |
| **Sudo not cached** | `sudo_check()` prompts once |
| **Sudo fails** | Package install fails → `set -e` aborts (unless guarded with `\|\| true`) |
| **Empty checklist (user cancels)** | Returns silently via `\|\| return` |
| **Stow not installed** | Bulk-stow step skipped; individual symlinks still work |
