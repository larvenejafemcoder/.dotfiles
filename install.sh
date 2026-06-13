#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# install.sh — Dotfiles deployment & interactive dev tools setup
# Supports fully automated install (--unattended), interactive TUI (--setup),
# and granular control via flags (--dotfiles-only, --tools-only, etc.)
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

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

# ── Automated install flags ─────────────────────────────────────────────────
DRY_RUN=false
UNATTENDED=false
ROLLBACK_MODE=false
DEBUG=false

# ── Individual component toggles (all enabled by default) ───────────────────
INSTALL_THEME=true
INSTALL_FONTS=true
INSTALL_STARSHIP=true
INSTALL_ZSH=true
INSTALL_RICE=false       # Gruvbox ricing (opt-in via --rice)
INSTALL_DEV=true
INSTALL_DOCKER=true
INSTALL_KVM=true
INSTALL_DESKTOP=true
INSTALL_NEOVIM=true
INSTALL_BRAVE=true
INSTALL_SSH=true
MINIMAL=false             # --minimal disables all optional components
DESKTOP_PROFILE="default"
GIT_USERNAME="${GIT_USERNAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"

# ── Interactive mode flags (--setup, --dotfiles-only, --tools-only) ────────
SETUP_MODE=false
DOTFILES_ONLY=false
TOOLS_ONLY=false
REPEAT=false
OFFLINE=false
FORCE=false

# ── Interactive setup directories and log paths ─────────────────────────────
SETUP_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-setup"
SETUP_CONFIG_FILE="$SETUP_CONFIG_DIR/selections.cfg"
SETUP_LOG_FILE="$SETUP_CONFIG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
SETUP_BACKUP_DIR="$SETUP_CONFIG_DIR/backups/$(date +%Y%m%d-%H%M%S)"
SETUP_HISTORY="$SETUP_CONFIG_DIR/history.log"
SETUP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-setup"

# ── Terminal colors (fallback to raw ANSI if scripts/core/colors.sh not loaded) ──
cR="${RED:-'\033[0;31m'}"   cG="${GREEN:-'\033[0;32m'}"
cY="${YELLOW:-'\033[1;33m'}" cB="${BLUE:-'\033[0;34m'}"
cC="${CYAN:-'\033[0;36m'}"  cM="${MAGENTA:-'\033[0;35m'}"
cN="${RESET:-'\033[0m'}"    cD="${DIM:-'\033[2m'}"
BOLD="${BOLD:-'\033[1m'}"

# ── Interactive logging helpers (write to SETUP_LOG_FILE + stderr) ──────────
setup_log()   { echo -e "$(date '+%H:%M:%S') | $*" | tee -a "$SETUP_LOG_FILE" >&2; }
setup_info()  { setup_log "${cB}INFO${cN}  $*"; }
setup_ok()    { setup_log "${cG}OK${cN}    $*"; }
setup_warn()  { setup_log "${cY}WARN${cN}  $*"; }
setup_err()   { setup_log "${cR}ERROR${cN} $*"; }

# ── TUI Backend — auto-detect dialog/whiptail, die gracefully if neither ────
TUI_BE=""
tui_init() {
    if command -v dialog &>/dev/null; then TUI_BE="dialog"
    elif command -v whiptail &>/dev/null; then TUI_BE="whiptail"
    else
        echo -e "${cY}Warning: neither dialog nor whiptail found.${cN}"
        echo -e "${cY}Install one: apt install dialog | pacman -S dialog${cN}"
        return 1
    fi
    return 0
}

# Thin wrappers around dialog/whiptail for consistent UX — fd 3 redirects stdout
tui_menu()      { local t="$1" m="$2"; shift 2; $TUI_BE --clear --backtitle "Dotfiles Setup" --title "$t" --menu "$m" 0 0 0 "$@" 3>&1 1>&2 2>&3; }
tui_checklist() { local t="$1" m="$2"; shift 2; $TUI_BE --clear --backtitle "Dotfiles Setup" --title "$t" --checklist "$m" 0 0 0 "$@" 3>&1 1>&2 2>&3; }
tui_msgbox()    { $TUI_BE --clear --backtitle "Dotfiles Setup" --title "$1" --msgbox "$2" 0 0 3>&1 1>&2 2>&3; }
tui_yesno()     { $TUI_BE --clear --backtitle "Dotfiles Setup" --title "$1" --yesno "$2" 0 0 3>&1 1>&2 2>&3; }

# ── Spinner — braille-based progress indicator for background commands ──────
setup_spinner() {
    local pid=$1 msg="${2:-Working...}" spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${cC}%s${cN} %s" "${spin:$i:1}" "$msg"
        i=$(( (i+1) % ${#spin} ))
        sleep 0.1
    done
    printf "\r${cG}✓${cN} %-60s\n" "$msg"
}

# Run a command in the background with a live spinner; log output silently
setup_run() {
    local msg="$1" rc; shift
    ("$@" 2>&1 | tee -a "$SETUP_LOG_FILE" >/dev/null) &
    setup_spinner $! "$msg"
    wait $!; rc=$?
    return $rc
}

# ── Dotfiles catalogue (name, description, default=off for whiptail checklist) ─
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

# Find the source path of a dotfile — searches stow packages first, then fallback dirs
dotfile_source() {
    local name="$1"
    local base="${name##*/}"
    for pkg in "$DOTFILES_DIR/stow/"*/; do
        [ -d "$pkg" ] || continue
        local pkg_name="$(basename "$pkg")"
        # e.g. ".config/alacritty" → matches "stow/alacritty/.config/alacritty"
        if [[ "$name" == ".config/$pkg_name"* ]] || [ -f "$pkg/$base" ]; then
            if [ -e "$pkg/$name" ]; then
                echo "$pkg/$name"
                return 0
            fi
        fi
    done
    # Fallback: probe common directories within the dotfiles repo
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

# Backup an existing dotfile before overwriting — preserves dir structure
backup_dotfile() {
    local target="$1"
    [ ! -e "$target" ] && return 0
    local bak="$SETUP_BACKUP_DIR/${target#/}"
    mkdir -p "$(dirname "$bak")"
    cp -rL "$target" "$bak" 2>/dev/null
    setup_ok "Backed up: $target"
}

# Symlink a dotfile (skips if already pointing at the right source)
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

# Interactive checklist for dotfiles with __all__ shortcut and GNU Stow option
interactive_dotfiles() {
    mkdir -p "$SETUP_BACKUP_DIR" "$SETUP_CONFIG_DIR" "$SETUP_CACHE"
    SETUP_SUMMARY=$(mktemp)

    local available=() name desc src
    for ((i=0; i<${#DOTFILES_ITEMS[@]}; i+=3)); do
        name="${DOTFILES_ITEMS[$i]}"
        desc="${DOTFILES_ITEMS[$((i+1))]}"
        src=$(dotfile_source "$name")
        [ -n "$src" ] && available+=("$name" "$desc" off)
    done

    if [ ${#available[@]} -eq 0 ]; then
        tui_msgbox "No Dotfiles" "No matching dotfiles found in $DOTFILES_DIR"
        return
    fi

    local choices
    choices=$(tui_checklist "Select Dotfiles" \
        "Choose dotfiles to symlink into your home directory.\nSPACE to toggle, ENTER to confirm." \
        "__all__"  "Install ALL available dotfiles" OFF \
        "${available[@]}" 2>&1) || return

    local count=0 all_flag=0
    echo "$choices" | grep -q "__all__" && all_flag=1

    for ((i=0; i<${#DOTFILES_ITEMS[@]}; i+=3)); do
        name="${DOTFILES_ITEMS[$i]}"
        src=$(dotfile_source "$name")
        [ -z "$src" ] && continue
        target="$HOME/$name"
        if [ "$all_flag" = 1 ] || echo "$choices" | grep -q "\"$name\""; then
            install_dotfile "$name" "$src" "$target"
            count=$((count+1))
        fi
    done

    # Optional bulk-stow for all stow-managed packages
    if command -v stow &>/dev/null && [ -d "$DOTFILES_DIR/stow" ]; then
        local pkgs=""
        for p in "$DOTFILES_DIR/stow/"*/; do pkgs="$pkgs $(basename "$p")"; done
        pkgs="${pkgs## }"
        if [ -n "$pkgs" ] && tui_yesno "GNU Stow" "Run stow for all packages?\nPackages: $pkgs"; then
            (cd "$DOTFILES_DIR/stow" && for p in $pkgs; do
                stow -R "$p" 2>/dev/null
                echo "  ✓ stow: $p" >> "$SETUP_SUMMARY"
                count=$((count+1))
            done)
        fi
    fi

    setup_ok "Dotfiles installed: $count files"
    echo "[dotfiles]" >> "$SETUP_CONFIG_FILE"
    echo "$choices" >> "$SETUP_CONFIG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M') | dotfiles: $count files" >> "$SETUP_HISTORY"
}

# ── Dev Tools (interactive) — install individual tools via package manager or script ─

# Install packages via the auto-detected package manager (from interactive_setup)
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

# Each install_*_interactive function checks if already installed, respects --offline, then installs
install_nodejs_interactive() {
    command -v node &>/dev/null && { setup_log "  ${cD}✓ Node.js already installed${cN}"; echo "  ✓ Node.js" >> "$SETUP_SUMMARY"; return 0; }
    [ "$OFFLINE" = 1 ] && { echo "  - Node.js (offline)" >> "$SETUP_SUMMARY"; return 0; }
    export NVM_DIR="$HOME/.nvm"
    [ ! -d "$NVM_DIR" ] && setup_run "Downloading nvm..." bash -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    command -v nvm &>/dev/null && setup_run "Installing Node.js LTS..." nvm install --lts --default
    echo "  ✓ Node.js (nvm)" >> "$SETUP_SUMMARY"
}

install_rust_interactive() {
    command -v rustc &>/dev/null && { setup_log "  ${cD}✓ Rust already installed${cN}"; echo "  ✓ Rust" >> "$SETUP_SUMMARY"; return 0; }
    [ "$OFFLINE" = 1 ] && { echo "  - Rust (offline)" >> "$SETUP_SUMMARY"; return 0; }
    setup_run "Installing Rust..." bash -c "curl -fsSL https://sh.rustup.rs | sh -s -- -y"
    source "$HOME/.cargo/env"
    echo "  ✓ Rust" >> "$SETUP_SUMMARY"
}

install_go_interactive() {
    command -v go &>/dev/null && { setup_log "  ${cD}✓ Go already installed${cN}"; echo "  ✓ Go" >> "$SETUP_SUMMARY"; return 0; }
    [ "$OFFLINE" = 1 ] && { echo "  - Go (offline)" >> "$SETUP_SUMMARY"; return 0; }
    local ver="1.23.4"
    setup_run "Downloading Go $ver..." curl -fsSL "https://go.dev/dl/go$ver.linux-amd64.tar.gz" -o /tmp/go.tar.gz
    sudo_check "install Go"
    sudo rm -rf /usr/local/go; sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH="/usr/local/go/bin:$PATH"
    echo "  ✓ Go $ver" >> "$SETUP_SUMMARY"
}

install_starship_interactive() {
    command -v starship &>/dev/null && { setup_log "  ${cD}✓ Starship already installed${cN}"; echo "  ✓ Starship" >> "$SETUP_SUMMARY"; return 0; }
    [ "$OFFLINE" = 1 ] && { echo "  - Starship (offline)" >> "$SETUP_SUMMARY"; return 0; }
    setup_run "Installing Starship..." bash -c "curl -fsSL https://starship.rs/install.sh | sh -s -- -y"
    echo "  ✓ Starship" >> "$SETUP_SUMMARY"
}

install_neovim_interactive() {
    command -v nvim &>/dev/null && { setup_log "  ${cD}✓ Neovim already installed${cN}"; echo "  ✓ Neovim" >> "$SETUP_SUMMARY"; return 0; }
    [ "$OFFLINE" = 1 ] && { echo "  - Neovim (offline)" >> "$SETUP_SUMMARY"; return 0; }
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo_check "add Neovim PPA"
        sudo add-apt-repository ppa:neovim-ppa/unstable -y 2>/dev/null || true
        sudo apt-get update -qq 2>/dev/null || true
    fi
    pkg_install_interactive neovim
    command -v nvim &>/dev/null && echo "  ✓ Neovim" >> "$SETUP_SUMMARY" || echo "  - Neovim (not installed)" >> "$SETUP_SUMMARY"
}

install_docker_interactive() {
    command -v docker &>/dev/null && { setup_log "  ${cD}✓ Docker already installed${cN}"; echo "  ✓ Docker" >> "$SETUP_SUMMARY"; return 0; }
    [ "$OFFLINE" = 1 ] && { echo "  - Docker (offline)" >> "$SETUP_SUMMARY"; return 0; }
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo_check "install Docker"
        curl -fsSL https://get.docker.com | sh 2>&1 | tee -a "$SETUP_LOG_FILE" >/dev/null
        sudo usermod -aG docker "$USER" 2>/dev/null || true
    else
        pkg_install_interactive docker docker-compose
    fi
    echo "  ✓ Docker" >> "$SETUP_SUMMARY"
}

# Interactive dev-tools checklist — dispatches selections to the install helpers above
interactive_tools() {
    SETUP_SUMMARY=${SETUP_SUMMARY:-$(mktemp)}

    local tools_sel
    tools_sel=$(tui_checklist "Dev Tools" "Select tools to install (SPACE to toggle, ENTER to confirm):" \
        "─── Languages ───"  "" OFF \
        "nodejs"    "Node.js via nvm"               OFF \
        "rust"      "Rust via rustup"               OFF \
        "go"        "Go language"                   OFF \
        "─── Terminal ───"  "" OFF \
        "starship"  "Starship prompt"                OFF \
        "tmux"      "Tmux + TPM"                    OFF \
        "─── Editors ───"   "" OFF \
        "neovim"    "Neovim (latest)"               OFF \
        "─── DevOps ───"    "" OFF \
        "docker"    "Docker + Compose"              OFF \
        "─── Utilities ───" "" OFF \
        "cli"       "eza, bat, fzf, ripgrep, fd, lazygit, jq, httpie, zoxide" OFF \
        2>&1) || return

    echo "[tools]" >> "$SETUP_CONFIG_FILE"
    echo "$tools_sel" >> "$SETUP_CONFIG_FILE"

    for tool in $tools_sel; do
        case "$tool" in
            nodejs)   install_nodejs_interactive;;
            rust)     install_rust_interactive;;
            go)       install_go_interactive;;
            starship) install_starship_interactive;;
            tmux)     pkg_install_interactive tmux
                      echo "  ✓ Tmux" >> "$SETUP_SUMMARY";;
            neovim)   install_neovim_interactive;;
            docker)   install_docker_interactive;;
            cli)      pkg_install_interactive eza bat fzf ripgrep fd-find lazygit jq httpie || true
                      [ "$OFFLINE" = 0 ] && command -v zoxide &>/dev/null || \
                        setup_run "Installing zoxide..." bash -c "curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash" 2>/dev/null || true
                      for u in eza bat fzf rg fd lazygit jq httpie zoxide; do
                          command -v "$u" &>/dev/null && echo "  ✓ $u" >> "$SETUP_SUMMARY"
                      done;;
        esac
    done

    setup_ok "Dev tools installation complete"
    echo "$(date '+%Y-%m-%d %H:%M') | tools: $tools_sel" >> "$SETUP_HISTORY"
}

# ── Interactive Setup Main — top-level menu (dotfiles | tools | exit) ───────

interactive_setup() {
    mkdir -p "$SETUP_CONFIG_DIR" "$SETUP_BACKUP_DIR" "$SETUP_CACHE"
    SETUP_SUMMARY=$(mktemp)

    echo "╔═══════════════════════════════════════════════╗"
    echo "║     Dotfiles & Dev Tools — Interactive Setup  ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""

    tui_init || { return 1; }

    # Auto-detect package manager so pkg_install_interactive works
    detect_package_manager 2>/dev/null || true
    PKG_MANAGER="${PKG_MANAGER:-apt}"
    case "$PKG_MANAGER" in
        apt)    PKG_INSTALL="sudo apt-get install -y -qq";;
        dnf)    PKG_INSTALL="sudo dnf install -y -q";;
        pacman) PKG_INSTALL="sudo pacman -S --noconfirm --needed";;
        *)      PKG_INSTALL="sudo apt-get install -y -qq";;
    esac

    while true; do
        local choice
        choice=$(tui_menu "Dotfiles Setup" \
            "Choose an option:" \
            "dotfiles" "Install / update dotfiles" \
            "tools"    "Install development tools" \
            "exit"     "Exit" 2>&1) || break

        case "$choice" in
            dotfiles) interactive_dotfiles;;
            tools)    interactive_tools;;
            exit)     break;;
        esac
    done

    if [ -s "$SETUP_SUMMARY" ]; then
        echo ""
        echo -e "${cG}Summary:${cN}"
        sort -u "$SETUP_SUMMARY" | while IFS= read -r line; do echo "  $line"; done
        echo ""
        echo -e "Log: ${cC}$SETUP_LOG_FILE${cN}"
    fi

    cp "$SETUP_LOG_FILE" "$SETUP_CONFIG_DIR/install-latest.log" 2>/dev/null || true
    rm -f "$SETUP_SUMMARY"
}

# Acquire sudo session if not already cached (prompts once)
sudo_check() {
    if ! sudo -n true 2>/dev/null; then
        setup_warn "Sudo needed: $*"
        sudo -v
    fi
}

# ── CLI argument parser — maps flags to global variables ────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tui)
                exec "$DOTFILES_DIR/tui.sh"
                ;;
            --setup|--interactive)
                SETUP_MODE=true
                ;;
            --dotfiles-only)
                SETUP_MODE=true; DOTFILES_ONLY=true
                ;;
            --tools-only)
                SETUP_MODE=true; TOOLS_ONLY=true
                ;;
            --repeat)
                SETUP_MODE=true; REPEAT=true
                ;;
            --offline)
                SETUP_MODE=true; OFFLINE=true
                ;;
            --force)
                FORCE=true
                ;;
            --dry-run) DRY_RUN=true ;;
            --unattended) UNATTENDED=true ;;
            --rollback) ROLLBACK_MODE=true ;;
            --debug) DEBUG=true ;;
            --minimal)
                MINIMAL=true
                INSTALL_THEME=false; INSTALL_FONTS=false; INSTALL_STARSHIP=false
                INSTALL_ZSH=false; INSTALL_DEV=false; INSTALL_DOCKER=false
                INSTALL_KVM=false; INSTALL_DESKTOP=false; INSTALL_NEOVIM=false
                INSTALL_BRAVE=false; INSTALL_SSH=false
                ;;
            --rice) INSTALL_RICE=true ;;
            --no-theme) INSTALL_THEME=false ;;
            --no-fonts) INSTALL_FONTS=false ;;
            --no-starship) INSTALL_STARSHIP=false ;;
            --no-zsh) INSTALL_ZSH=false ;;
            --no-dev) INSTALL_DEV=false ;;
            --no-docker) INSTALL_DOCKER=false ;;
            --no-kvm) INSTALL_KVM=false ;;
            --no-desktop) INSTALL_DESKTOP=false ;;
            --no-neovim) INSTALL_NEOVIM=false ;;
            --no-brave) INSTALL_BRAVE=false ;;
            --no-ssh) INSTALL_SSH=false ;;
            --profile)
                shift; DESKTOP_PROFILE="$1"
                ;;
            --git-name)
                shift; GIT_USERNAME="$1"
                ;;
            --git-email)
                shift; GIT_EMAIL="$1"
                ;;
            --help|-h)
                echo "Usage: ./install.sh [OPTIONS]"
                echo ""
                echo "Automated install:"
                echo "  --tui               Interactive TUI (Textual-based)"
                echo "  --dry-run           Simulate without making changes"
                echo "  --unattended        No prompts, full automation"
                echo "  --rollback          Roll back previous deployment"
                echo "  --debug             Enable verbose debug output"
                echo ""
                echo "Interactive selection:"
                echo "  --setup, --interactive  Interactive dotfiles & tools menu"
                echo "  --dotfiles-only         Interactive dotfiles selection only"
                echo "  --tools-only            Interactive tools selection only"
                echo "  --repeat                Re-run with saved selections"
                echo "  --offline               Skip downloads, use cache only"
                echo "  --force                 Overwrite without confirmation"
                echo ""
                echo "Profiles:"
                echo "  --minimal           Config symlinks only"
                echo "  --profile hyprland  Hyprland environment"
                echo "  --profile i3        I3 environment"
                echo "  --rice              Gruvbox ricing"
                echo ""
                echo "Skips:"
                echo "  --no-theme --no-fonts --no-starship --no-zsh"
                echo "  --no-dev --no-docker --no-kvm --no-desktop"
                echo "  --no-neovim --no-brave --no-ssh"
                echo ""
                echo "Git config:"
                echo "  --git-name 'Name'   Git user name"
                echo "  --git-email 'email' Git user email"
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${RESET}"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
        shift
    done
}

# ── Deployment status tracker (assoc array used by draw_dashboard) ──────────
declare -A DEPLOY_STATUS
init_status() {
    DEPLOY_STATUS=( ["Detection"]="pending" ["Packages"]="pending" ["Dotfiles"]="pending" ["Shell"]="pending" ["Dev Tools"]="pending" ["Fonts"]="pending" ["Docker"]="pending" ["KVM"]="pending" ["Desktop"]="pending" ["Themes"]="pending" ["Neovim"]="pending" ["Brave"]="pending" ["SSH Keys"]="pending" ["Verification"]="pending" )
}

update_status() {
    local key="$1"
    local value="$2"
    DEPLOY_STATUS["$key"]="$value"
}

# Load optional .env and merge into Git/desktop config variables
import_env_config() {
    local env_file="${DOTFILES_DIR}/.env"
    if [[ -f "$env_file" ]]; then
        log_info "Loading .env configuration..."
        set -a
        source "$env_file"
        set +a
    fi

    GIT_USERNAME="${GIT_USERNAME:-${DOTFILES_GIT_USERNAME:-}}"
    GIT_EMAIL="${GIT_EMAIL:-${DOTFILES_GIT_EMAIL:-}}"
    DESKTOP_PROFILE="${DESKTOP_PROFILE:-${DOTFILES_DESKTOP_PROFILE:-default}}"

    export GIT_USERNAME GIT_EMAIL DESKTOP_PROFILE
}

main() {
    parse_args "$@"

    # Interactive modes
    if [[ "$SETUP_MODE" == "true" ]]; then
        if [[ "$DOTFILES_ONLY" == "true" ]]; then
            mkdir -p "$SETUP_CONFIG_DIR" "$SETUP_BACKUP_DIR"
            SETUP_SUMMARY=$(mktemp)
            tui_init && interactive_dotfiles
            [ -s "$SETUP_SUMMARY" ] && { echo -e "\n${cG}Summary:${cN}"; sort -u "$SETUP_SUMMARY" | while IFS= read -r line; do echo "  $line"; done; }
            rm -f "$SETUP_SUMMARY"
        elif [[ "$TOOLS_ONLY" == "true" ]]; then
            interactive_tools
        else
            interactive_setup
        fi
        exit 0
    fi

    if [[ "$ROLLBACK_MODE" == "true" ]]; then
        draw_header
        source "$DOTFILES_DIR/scripts/dotfiles/deploy.sh"
        init_deploy
        rollback_symlinks
        exit 0
    fi

    collect_stats
    init_status
    init_logging

    import_env_config

    # ── Phase 1: Boot Sequence ──
    draw_boot_screen

    # ── Phase 2: Environment Detection ──
    update_status "Detection" "running"
    detect_environment
    detect_package_manager
    display_summary
    update_status "Detection" "completed"
    sleep 0.5

    # ── Phase 3: Package Installation ──
    update_status "Packages" "running"
    draw_section "PACKAGE INSTALLATION"
    if [[ "$MINIMAL" == "false" ]]; then
        pkg_update
        local pkg_file="$DOTFILES_DIR/config/packages/${DISTRO}.txt"
        if [[ -f "$pkg_file" ]]; then
            log_info "Installing packages from ${pkg_file}..."
            pkg_install_from_file "$pkg_file"
        else
            log_warn "No package list found for ${DISTRO}"
        fi
    else
        log_info "Minimal mode: skipping package installation"
    fi
    update_status "Packages" "completed"

    # ── Phase 4: Dotfile Deployment ──
    update_status "Dotfiles" "running"
    deploy_symlinks
    update_status "Dotfiles" "completed"

    if [[ "$MINIMAL" == "false" ]]; then
        # ── Shell Setup ──
        if [[ "$INSTALL_ZSH" == "true" ]] || [[ "$INSTALL_STARSHIP" == "true" ]]; then
            update_status "Shell" "running"
            setup_shell
            update_status "Shell" "completed"
        else
            update_status "Shell" "skipped"
        fi

        # ── Fonts ──
        if [[ "$INSTALL_FONTS" == "true" ]]; then
            update_status "Fonts" "running"
            setup_fonts
            update_status "Fonts" "completed"
        else
            update_status "Fonts" "skipped"
        fi

        # ── Developer Tools ──
        if [[ "$INSTALL_DEV" == "true" ]]; then
            update_status "Dev Tools" "running"
            setup_development
            update_status "Dev Tools" "completed"
        else
            update_status "Dev Tools" "skipped"
        fi

        # ── Docker ──
        if [[ "$INSTALL_DOCKER" == "true" ]]; then
            update_status "Docker" "running"
            setup_docker
            update_status "Docker" "completed"
        else
            update_status "Docker" "skipped"
        fi

        # ── KVM / Virtualization ──
        if [[ "$INSTALL_KVM" == "true" ]]; then
            update_status "KVM" "running"
            setup_kvm
            update_status "KVM" "completed"
        else
            update_status "KVM" "skipped"
        fi

        # ── Desktop Profile ──
        if [[ "$INSTALL_DESKTOP" == "true" ]]; then
            update_status "Desktop" "running"
            setup_desktop
            update_status "Desktop" "completed"
        else
            update_status "Desktop" "skipped"
        fi

        # ── Themes ──
        if [[ "$INSTALL_THEME" == "true" ]]; then
            update_status "Themes" "running"
            setup_themes
            update_status "Themes" "completed"
        else
            update_status "Themes" "skipped"
        fi

        # ── Neovim ──
        if [[ "$INSTALL_NEOVIM" == "true" ]]; then
            update_status "Neovim" "running"
            setup_neovim
            update_status "Neovim" "completed"
        else
            update_status "Neovim" "skipped"
        fi

        # ── Brave Browser ──
        if [[ "$INSTALL_BRAVE" == "true" ]]; then
            update_status "Brave" "running"
            setup_brave
            update_status "Brave" "completed"
        else
            update_status "Brave" "skipped"
        fi

        # ── SSH Keys ──
        if [[ "$INSTALL_SSH" == "true" ]]; then
            update_status "SSH Keys" "running"
            setup_ssh_keys
            update_status "SSH Keys" "completed"
        else
            update_status "SSH Keys" "skipped"
        fi

        # ── Rice (optional) ──
        if [[ "$INSTALL_RICE" == "true" ]]; then
            if [[ -f "$DOTFILES_DIR/shell/rice.sh" ]]; then
                draw_section "GRUVBOX RICING"
                bash "$DOTFILES_DIR/shell/rice.sh"
            fi
        fi

        # ── Restore GNOME Terminal (if backup exists) ──
        if [[ -f "$DOTFILES_DIR/gnome-terminal/gnome-terminal.dconf" ]] && [[ -s "$DOTFILES_DIR/gnome-terminal/gnome-terminal.dconf" ]]; then
            if command -v dconf &>/dev/null; then
                draw_section "TERMINAL PROFILE"
                log_info "Restoring GNOME Terminal profile..."
                dconf load /org/gnome/terminal/ < "$DOTFILES_DIR/gnome-terminal/gnome-terminal.dconf"
                log_success "GNOME Terminal profile restored"
            fi
        fi
    fi

    # ── Phase 6: Visual Dashboard ──
    draw_section "DEPLOYMENT DASHBOARD"
    draw_dashboard DEPLOY_STATUS
    sleep 1

    # ── Phase 7: Verification & Report ──
    update_status "Verification" "running"
    run_verification
    update_status "Verification" "completed"

    # Final Display
    echo
    if command -v fastfetch &>/dev/null; then
        fastfetch
    elif command -v neofetch &>/dev/null; then
        neofetch
    fi

    final_banner

    log_success "Deployment completed at $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo -e "  ${DIM}Log file: ${LOG_FILE}${RESET}"
    echo

    if [[ "$INSTALL_ZSH" == "true" ]] && [[ "$SHELL" != *"zsh"* ]]; then
        echo -e "  ${YELLOW}Next steps:${RESET}"
        echo -e "   1. Run: ${CYAN}chsh -s \"$(which zsh)\"${RESET}   (set Zsh as default shell)"
        echo -e "   2. Run: ${CYAN}exec zsh${RESET}   (start Zsh)"
        echo -e "   3. Run: ${CYAN}exec bash${RESET}  (back to Bash)"
        echo
    fi
}

main "$@"
