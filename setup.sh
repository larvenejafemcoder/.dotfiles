#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# setup.sh — Interactive Dotfiles & Dev Tools Installer
# Usage: bash setup.sh [--dotfiles-only] [--tools-only] [--repeat] [--offline]
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
IFS=$'\n\t'

# ── Config ──────────────────────────────────────────────────────────────────
DOTFILES_REPO="${DOTFILES_REPO:-$HOME/.dotfiles}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-setup"
CONFIG_FILE="$CONFIG_DIR/selections.cfg"
LOG_FILE="$CONFIG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
LOG_FILE_LATEST="$CONFIG_DIR/setup-latest.log"
BACKUP_DIR="$CONFIG_DIR/backups/$(date +%Y%m%d-%H%M%S)"
SUMMARY_FILE=$(mktemp)
HISTORY_FILE="$CONFIG_DIR/history.log"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-setup"

mkdir -p "$CONFIG_DIR" "$CACHE_DIR"

force=0
dotfiles_only=0
tools_only=0
offline=0
repeat=0

# ── Color Output ────────────────────────────────────────────────────────────
cR='\033[0;31m'; cG='\033[0;32m'; cY='\033[1;33m'
cB='\033[0;34m'; cC='\033[0;36m'; cM='\033[0;35m'
cW='\033[1;37m'; cN='\033[0m'
BOLD='\033[1m'; DIM='\033[2m'

# ── Logging ─────────────────────────────────────────────────────────────────
log()   { echo -e "$(date '+%H:%M:%S') | $*" | tee -a "$LOG_FILE" >&2; }
info()  { log "${cB}INFO${cN}  $*"; }
ok()    { log "${cG}OK${cN}    $*"; }
warn()  { log "${cY}WARN${cN}  $*"; }
err()   { log "${cR}ERROR${cN} $*"; }
header(){ echo -e "\n${cM}═══════════════════════════════════════════${cN}"; echo -e "${cW}$*${cN}"; echo -e "${cM}═══════════════════════════════════════════${cN}"; }
summary(){ echo "$*" >> "$SUMMARY_FILE"; }

cleanup() {
    rm -f "$SUMMARY_FILE"
    [ -n "${TMP_CHECKLIST:-}" ] && rm -f "$TMP_CHECKLIST"
}
trap cleanup EXIT

# ── TUI Backend Detection ──────────────────────────────────────────────────
TUI_BACKEND=""
tui_init() {
    if command -v dialog &>/dev/null; then
        TUI_BACKEND="dialog"
    elif command -v whiptail &>/dev/null; then
        TUI_BACKEND="whiptail"
    else
        err "Neither dialog nor whiptail found. Install one:"
        err "  apt/brew install dialog  |  pacman -S dialog  |  dnf install dialog"
        exit 1
    fi
    info "Using TUI backend: $TUI_BACKEND"
}

tui_menu() {
    local title="$1" text="$2" tag; shift 2
    case "$TUI_BACKEND" in
        dialog)  dialog --clear --backtitle "Dotfiles Setup" --title "$title" --menu "$text" 0 0 0 "$@" 3>&1 1>&2 2>&3 ;;
        whiptail) whiptail --clear --backtitle "Dotfiles Setup" --title "$title" --menu "$text" 20 70 10 "$@" 3>&1 1>&2 2>&3 ;;
    esac
    return $?
}

tui_checklist() {
    local title="$1" text="$2"; shift 2
    case "$TUI_BACKEND" in
        dialog)  dialog --clear --backtitle "Dotfiles Setup" --title "$title" --checklist "$text" 0 0 0 "$@" 3>&1 1>&2 2>&3 ;;
        whiptail) whiptail --clear --backtitle "Dotfiles Setup" --title "$title" --checklist "$text" 20 78 10 "$@" 3>&1 1>&2 2>&3 ;;
    esac
    return $?
}

tui_msgbox()   { $TUI_BACKEND --clear --backtitle "Dotfiles Setup" --title "$1" --msgbox "$2" 0 0 3>&1 1>&2 2>&3; }
tui_yesno()    { $TUI_BACKEND --clear --backtitle "Dotfiles Setup" --title "$1" --yesno "$2" 0 0 3>&1 1>&2 2>&3; }
tui_infobox()  { $TUI_BACKEND --clear --backtitle "Dotfiles Setup" --title "$1" --infobox "$2" 0 0 3>&1 1>&2 2>&3; }
tui_gauge()    {
    local title="$1"; shift
    case "$TUI_BACKEND" in
        dialog)   dialog --clear --backtitle "Dotfiles Setup" --title "$title" --gauge "$@" 6 60 0 ;;
        whiptail) whiptail --clear --backtitle "Dotfiles Setup" --title "$title" --gauge "$@" 6 60 0 ;;
    esac
}

# ── Spinner for background tasks ────────────────────────────────────────────
spinner() {
    local pid=$1 msg="${2:-Working...}" spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${cC}%s${cN} %s" "${spin:$i:1}" "$msg"
        i=$(( (i+1) % ${#spin} ))
        sleep 0.1
    done
    printf "\r${cG}✓${cN} %-60s\n" "$msg"
}

run_spinner() {
    local msg="$1" rc; shift
    ("$@" 2>&1 | tee -a "$LOG_FILE" >/dev/null) &
    spinner $! "$msg"
    wait $!; rc=$?
    return $rc
}

# ── System Detection ────────────────────────────────────────────────────────
detect_pkg_manager() {
    for pm in apt-get apt dnf pacman zypper apk brew; do
        if command -v "$pm" &>/dev/null; then
            case "$pm" in
                apt-get|apt)      echo "apt";  return 0;;
                dnf)              echo "dnf";  return 0;;
                pacman)           echo "pacman"; return 0;;
                zypper)           echo "zypper"; return 0;;
                apk)              echo "apk";  return 0;;
                brew)             echo "brew"; return 0;;
            esac
        fi
    done
    echo "unknown"; return 1
}

PKG_MANAGER=$(detect_pkg_manager)
PKG_INSTALL=""
PKG_UPDATE=""
case "$PKG_MANAGER" in
    apt)    PKG_UPDATE="sudo apt-get update -qq";     PKG_INSTALL="sudo apt-get install -y -qq";;
    dnf)    PKG_UPDATE="sudo dnf check-update -q";     PKG_INSTALL="sudo dnf install -y -q";;
    pacman) PKG_UPDATE="sudo pacman -Sy";              PKG_INSTALL="sudo pacman -S --noconfirm --needed";;
    zypper) PKG_UPDATE="sudo zypper refresh";          PKG_INSTALL="sudo zypper install -y";;
    apk)    PKG_UPDATE="sudo apk update -q";           PKG_INSTALL="sudo apk add -q";;
    brew)   PKG_UPDATE="brew update -q";               PKG_INSTALL="brew install -q";;
esac

detect_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
        echo 1; return 0
    fi
    echo 0; return 1
}

IS_WSL=$(detect_wsl)
IS_LINUX=1
[ "$(uname)" = "Darwin" ] && IS_LINUX=0

# ── Sudo Helper ─────────────────────────────────────────────────────────────
sudo_check() {
    if ! sudo -n true 2>/dev/null; then
        warn "Sudo access needed for: $*"
        sudo -v
    fi
}

# ── Package Install ─────────────────────────────────────────────────────────
pkg_install() {
    local pkg_list=()
    for pkg in "$@"; do pkg_list+=("$pkg"); done
    if [ ${#pkg_list[@]} -eq 0 ]; then return 0; fi
    if [ "$offline" = 1 ]; then
        warn "Offline mode — skipping: ${pkg_list[*]}"
        return 0
    fi
    info "Installing: ${pkg_list[*]}"
    echo "  → $PKG_INSTALL ${pkg_list[*]}" >> "$LOG_FILE"
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo_check "package install (${pkg_list[*]})"
    fi
    $PKG_INSTALL "${pkg_list[@]}" 2>&1 | tee -a "$LOG_FILE" >/dev/null
    local rc=${PIPESTATUS[0]}
    if [ "$rc" -eq 0 ]; then
        ok "Installed: ${pkg_list[*]}"
    else
        err "Failed to install: ${pkg_list[*]}"
    fi
    return $rc
}

pkg_ensure() {
    local cmd="$1" pkg="${2:-$1}"
    if ! command -v "$cmd" &>/dev/null; then
        pkg_install "$pkg"
    else
        log "  ${DIM}✓ $cmd already installed${cN}"
    fi
}

# ── Download helper ─────────────────────────────────────────────────────────
download() {
    local url="$1" dest="$2"
    if [ "$offline" = 1 ]; then
        [ -f "$dest" ] && return 0 || { warn "Offline — can't download $url"; return 1; }
    fi
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$dest"
    else
        err "Need curl or wget to download"; return 1
    fi
}

# ── Config Save / Load ──────────────────────────────────────────────────────
save_config() {
    local section="$1" cmd; shift
    # Remove existing section
    sed -i "/^\[$section\]/,/^\[/ { /^\[$section\]/d; /^\[/!d }" "$CONFIG_FILE" 2>/dev/null || true
    echo "[$section]" >> "$CONFIG_FILE"
    for item in "$@"; do echo "$item" >> "$CONFIG_FILE"; done
}

save_value() {
    local section="$1" key="$2" value="$3"
    if grep -q "^\[$section\]" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "/^\[$section\]/,/^\[/{s/^$key=.*/$key=$value/}" "$CONFIG_FILE"
    else
        echo "[$section]" >> "$CONFIG_FILE"
        echo "$key=$value" >> "$CONFIG_FILE"
    fi
}

load_config() {
    local section="$1"
    awk "/^\[$section\]/{flag=1;next} /^\[/{flag=0} flag && NF" "$CONFIG_FILE" 2>/dev/null || true
}

load_value() {
    local section="$1" key="$2" default="${3:-}"
    awk -F= -v s="[$section]" -v k="$key" '$0==s{f=1;next} /^\[/{f=0} f&&$1==k{print $2;exit}' "$CONFIG_FILE" 2>/dev/null || echo "$default"
}

append_history() {
    echo "$(date '+%Y-%m-%d %H:%M') | $*" >> "$HISTORY_FILE"
}

# ─────────────────────────────────────────────────────────────────────────────
# PART 1: DOTFILES MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────

# Dotfiles available for symlinking
DOTFILES_DEFS=(
    ".zshrc"        "Zsh configuration"           "off"
    ".bashrc"       "Bash configuration"           "off"
    ".vimrc"        "Vim configuration"            "off"
    ".tmux.conf"    "Tmux configuration"           "off"
    ".gitconfig"    "Git configuration"            "off"
    ".config/alacritty" "Alacritty terminal config" "off"
    ".config/nvim"  "Neovim configuration"         "off"
    ".config/i3"    "I3 window manager config"     "off"
    ".config/kitty" "Kitty terminal config"        "off"
    ".config/starship.toml" "Starship prompt config" "off"
    ".config/fish"  "Fish shell config"            "off"
)

dotfile_source() {
    # Look for the file in various locations
    local name="$1"
    # Check stow packages first
    local stow_pkg="${name##*/}"; stow_pkg="${stow_pkg#.}"
    [ "$stow_pkg" = "alacritty" ] && stow_pkg="alacritty"
    [ -d "$DOTFILES_REPO/stow/$stow_pkg" ] && { echo "$DOTFILES_REPO/stow/$stow_pkg"; return 0; }
    # Check direct paths
    [ -f "$DOTFILES_REPO/$name" ] && { echo "$DOTFILES_REPO/$name"; return 0; }
    [ -f "$DOTFILES_REPO/home/$name" ] && { echo "$DOTFILES_REPO/home/$name"; return 0; }
    # Check shell/, git/, etc.
    local base="${name##*/}"
    local dir="${name#.}"
    dir="${dir%%/*}"
    [ -f "$DOTFILES_REPO/$dir/$name" ] && { echo "$DOTFILES_REPO/$dir/$name"; return 0; }
    [ -f "$DOTFILES_REPO/shell/$name" ] && { echo "$DOTFILES_REPO/shell/$name"; return 0; }
    [ -f "$DOTFILES_REPO/git/$name" ] && { echo "$DOTFILES_REPO/git/$name"; return 0; }
    [ -f "$DOTFILES_REPO/tmux/$name" ] && { echo "$DOTFILES_REPO/tmux/$name"; return 0; }
    [ -f "$DOTFILES_REPO/terminal/$name" ] && { echo "$DOTFILES_REPO/terminal/$name"; return 0; }
    [ -f "$DOTFILES_REPO/config/$base" ] && { echo "$DOTFILES_REPO/config/$base"; return 0; }
    return 1
}

backup_file() {
    local target="$1"
    [ ! -e "$target" ] && return 0
    local bak="$BACKUP_DIR/${target#/}"
    mkdir -p "$(dirname "$bak")"
    cp -rL "$target" "$bak" 2>/dev/null
    ok "Backed up: $target → $bak"
}

install_dotfile() {
    local name="$1" src="$2" target="$3"
    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
        log "  ${DIM}✓ $name already linked correctly${cN}"
        summary "  ✓ $name (already linked)"
        return 0
    fi
    backup_file "$target"
    rm -rf "$target" 2>/dev/null || true
    ln -sf "$src" "$target"
    ok "Linked: $name → $target"
    summary "  ✓ $name → $target"
}

run_dotfiles() {
    header "Dotfiles Setup"
    # Check if repo exists
    if [ ! -d "$DOTFILES_REPO" ]; then
        DOTFILES_REPO="$(cd "$(dirname "$0")" && pwd)"
        info "Using local directory as dotfiles repo: $DOTFILES_REPO"
    fi

    local choices
    # Build checklist items
    local items=()
    for ((i=0; i<${#DOTFILES_DEFS[@]}; i+=3)); do
        items+=("${DOTFILES_DEFS[$i]}" "${DOTFILES_DEFS[$i+1]}" "${DOTFILES_DEFS[$i+2]}")
    done

    # Check which dotfiles actually exist in the repo
    local available=()
    for ((i=0; i<${#DOTFILES_DEFS[@]}; i+=3)); do
        local name="${DOTFILES_DEFS[$i]}"
        local desc="${DOTFILES_DEFS[$i+1]}"
        local src=$(dotfile_source "$name")
        if [ -n "$src" ]; then
            available+=("$name" "$desc" "off")
        fi
    done

    if [ ${#available[@]} -eq 0 ]; then
        tui_msgbox "No Dotfiles Found" "No matching dotfiles found in $DOTFILES_REPO.\nCheck DOTFILES_REPO or run from your dotfiles directory."
        return
    fi

    local menu_title="Dotfiles Selection"
    local menu_text="Select dotfiles to symlink into your home directory.\nRepo: $DOTFILES_REPO\nUse SPACE to select, ENTER to confirm."

    # Add special options
    choices=$(tui_checklist "$menu_title" "$menu_text" \
        "__all__"     "Install ALL available dotfiles (overrides other selections)" OFF \
        "__none__"    "Install NONE (skip dotfiles entirely)" OFF \
        "${available[@]}" 2>&1)
    local rc=$?
    [ "$rc" -ne 0 ] && { info "Dotfiles cancelled."; return 1; }

    mkdir -p "$BACKUP_DIR"
    info "Backup dir: $BACKUP_DIR"

    local count=0
    if echo "$choices" | grep -q "__none__"; then
        info "Skipping all dotfiles."
        return 0
    fi

    local install_all=0
    echo "$choices" | grep -q "__all__" && install_all=1

    for ((i=0; i<${#DOTFILES_DEFS[@]}; i+=3)); do
        local name="${DOTFILES_DEFS[$i]}"
        local src=$(dotfile_source "$name")
        [ -z "$src" ] && continue
        local target="$HOME/$name"

        if [ "$install_all" = 1 ] || echo "$choices" | grep -q "\"$name\""; then
            mkdir -p "$BACKUP_DIR"
            install_dotfile "$name" "$src" "$target"
            count=$((count+1))
        fi
    done

    # Also try stow if available
    if command -v stow &>/dev/null && [ -d "$DOTFILES_REPO/stow" ]; then
        local stow_packages=""
        for pkg in "$DOTFILES_REPO/stow/"*/; do
            pkg=$(basename "$pkg")
            stow_packages="$stow_packages $pkg"
        done
        stow_packages="${stow_packages## }"
        if [ -n "$stow_packages" ]; then
            info "GNU Stow packages available: $stow_packages"
            if tui_yesno "GNU Stow" "Run stow for all packages?\nPackages: $stow_packages"; then
                cd "$DOTFILES_REPO/stow"
                for pkg in $stow_packages; do
                    run_spinner "Stowing $pkg..." stow -R "$pkg"
                    summary "  ✓ stow: $pkg"
                    count=$((count+1))
                done
                cd "$OLDPWD"
            fi
        fi
    fi

    ok "Dotfiles installed: $count files"
    save_config "dotfiles" "$choices"
    append_history "dotfiles: installed $count files"
}

# ─────────────────────────────────────────────────────────────────────────────
# PART 2: DEV TOOLS INSTALLATION
# ─────────────────────────────────────────────────────────────────────────────

# ── Language Runtimes ───────────────────────────────────────────────────────

install_nodejs() {
    header "Node.js via nvm"
    if command -v node &>/dev/null && [ "$(node --version 2>/dev/null | cut -d. -f1 | tr -d v)" -ge 18 ]; then
        ok "Node.js $(node --version) already installed"
        summary "  ✓ Node.js $(node --version)"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping Node.js"
        summary "  - Node.js (skipped — offline)"
        return 0
    fi
    export NVM_DIR="$HOME/.nvm"
    if [ ! -d "$NVM_DIR" ]; then
        run_spinner "Downloading nvm..." \
            bash -c "download https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh /tmp/nvm-install.sh && bash /tmp/nvm-install.sh"
    fi
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    if command -v nvm &>/dev/null; then
        run_spinner "Installing Node.js LTS..." nvm install --lts --default
        summary "  ✓ Node.js LTS (via nvm)"
    fi
}

install_python() {
    header "Python (pyenv)"
    if command -v pyenv &>/dev/null; then
        local ver=$(pyenv versions --bare 2>/dev/null | tail -1)
        ok "pyenv ready${ver:+ (latest: $ver)}"
        summary "  ✓ Python (pyenv)"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping Python"
        summary "  - Python (skipped — offline)"; return 0
    fi
    pkg_ensure make gcc libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev || true
    run_spinner "Installing pyenv..." \
        bash -c "download https://pyenv.run /tmp/pyenv-install.sh && bash /tmp/pyenv-install.sh"
    export PATH="$HOME/.pyenv/bin:$PATH"
    [ -f "$HOME/.pyenv/bin/pyenv" ] && summary "  ✓ pyenv installed"
}

install_go() {
    header "Go"
    if command -v go &>/dev/null; then
        ok "Go $(go version 2>/dev/null | grep -oP 'go\K[0-9.]+') already installed"
        summary "  ✓ Go $(go version 2>/dev/null | grep -oP 'go\K[0-9.]+')"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping Go"; summary "  - Go (skipped — offline)"; return 0
    fi
    local ver="1.23.4"
    local tarball="/tmp/go$ver.linux-amd64.tar.gz"
    run_spinner "Downloading Go $ver..." download "https://go.dev/dl/go$ver.linux-amd64.tar.gz" "$tarball"
    sudo_check "install Go to /usr/local"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$tarball"
    export PATH="/usr/local/go/bin:$PATH"
    ok "Go $ver installed"
    summary "  ✓ Go $ver"
}

install_rust() {
    header "Rust (rustup)"
    if command -v rustc &>/dev/null; then
        ok "Rust $(rustc --version 2>/dev/null | cut -d' ' -f2) already installed"
        summary "  ✓ Rust $(rustc --version 2>/dev/null | cut -d' ' -f2)"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping Rust"; summary "  - Rust (skipped — offline)"; return 0
    fi
    run_spinner "Installing Rust via rustup..." \
        bash -c "download https://sh.rustup.rs /tmp/rustup-init.sh && sh /tmp/rustup-init.sh -y"
    source "$HOME/.cargo/env"
    ok "Rust installed"
    summary "  ✓ Rust (rustup)"
}

install_java() {
    header "Java (OpenJDK 17)"
    if command -v java &>/dev/null && java -version 2>&1 | grep -q "17"; then
        ok "OpenJDK 17 already installed"
        summary "  ✓ OpenJDK 17"
        return 0
    fi
    pkg_ensure openjdk-17-jdk || pkg_ensure java-17-openjdk || pkg_ensure jdk17 || warn "Java 17 not available via package manager"
    command -v java &>/dev/null && summary "  ✓ OpenJDK 17" || summary "  - Java (not installed)"
}

install_ruby() {
    header "Ruby (rbenv)"
    if command -v ruby &>/dev/null; then
        ok "Ruby $(ruby --version 2>/dev/null | cut -d' ' -f2) already installed"
        summary "  ✓ Ruby $(ruby --version 2>/dev/null | cut -d' ' -f2)"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping Ruby"; summary "  - Ruby (skipped — offline)"; return 0
    fi
    pkg_ensure rbenv || {
        run_spinner "Installing rbenv..." \
            bash -c "download https://raw.githubusercontent.com/rbenv/rbenv/master/bin/rbenv-install /tmp/rbenv-install.sh && bash /tmp/rbenv-install.sh"
    }
    summary "  ✓ Ruby (rbenv)"
}

# ── Terminal & Shell ────────────────────────────────────────────────────────

install_zsh_omz() {
    header "Zsh + Oh-My-Zsh"
    pkg_ensure zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        if [ "$offline" = 1 ]; then
            warn "Offline — skipping Oh-My-Zsh"; summary "  - Oh-My-Zsh (skipped — offline)"; return 0
        fi
        run_spinner "Installing Oh-My-Zsh..." \
            bash -c "download https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh /tmp/omz-install.sh && bash /tmp/omz-install.sh --unattended"
    fi
    # Install plugins
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ] && [ "$offline" = 0 ]; then
        run_spinner "Installing zsh-syntax-highlighting..." \
            git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    fi
    if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ] && [ "$offline" = 0 ]; then
        run_spinner "Installing zsh-autosuggestions..." \
            git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$zsh_custom/plugins/zsh-autosuggestions" 2>/dev/null || true
    fi
    # Change default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        sudo_check "change shell to zsh"
        chsh -s "$(which zsh)" 2>/dev/null && ok "Default shell changed to zsh" || warn "Couldn't change shell (run chsh manually)"
    fi
    ok "Zsh + Oh-My-Zsh ready"
    summary "  ✓ Zsh + Oh-My-Zsh"
}

install_starship() {
    header "Starship Prompt"
    if command -v starship &>/dev/null; then
        ok "Starship $(starship --version 2>/dev/null | head -1) already installed"
        summary "  ✓ Starship"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping Starship"; summary "  - Starship (skipped — offline)"; return 0
    fi
    run_spinner "Installing Starship..." \
        bash -c "download https://starship.rs/install.sh /tmp/starship-install.sh && sh /tmp/starship-install.sh -y"
    summary "  ✓ Starship"
}

install_fish() {
    header "Fish Shell"
    if command -v fish &>/dev/null; then
        ok "Fish $(fish --version 2>/dev/null | cut -d' ' -f3) already installed"
        summary "  ✓ Fish"
        return 0
    fi
    pkg_ensure fish
    summary "  ✓ Fish"
}

install_tmux() {
    header "Tmux"
    pkg_ensure tmux
    if [ ! -d "$HOME/.tmux/plugins/tpm" ] && [ "$offline" = 0 ]; then
        run_spinner "Installing Tmux Plugin Manager..." \
            git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null || true
    fi
    summary "  ✓ Tmux + TPM"
}

install_terminal() {
    header "Terminal Emulator"
    local emulator="${1:-alacritty}"
    pkg_ensure "$emulator" || warn "Could not install $emulator via package manager"
    if command -v "$emulator" &>/dev/null; then
        summary "  ✓ $emulator"
    else
        summary "  - $emulator (not installed)"
    fi
}

# ── Editors ─────────────────────────────────────────────────────────────────

install_neovim() {
    header "Neovim (latest)"
    if command -v nvim &>/dev/null; then
        local ver=$(nvim --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+')
        ok "Neovim $ver already installed"
        summary "  ✓ Neovim $ver"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping Neovim"; summary "  - Neovim (skipped — offline)"; return 0
    fi
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo_check "add neovim ppa"
        sudo add-apt-repository ppa:neovim-ppa/unstable -y 2>/dev/null || true
        sudo apt-get update -qq 2>/dev/null || true
    fi
    pkg_ensure neovim nvim
    command -v nvim &>/dev/null && summary "  ✓ Neovim" || summary "  - Neovim (not installed)"
}

install_vscode() {
    header "VS Code"
    if command -v code &>/dev/null; then
        ok "VS Code already installed"
        summary "  ✓ VS Code"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping VS Code"; summary "  - VS Code (skipped — offline)"; return 0
    fi
    case "$PKG_MANAGER" in
        apt)
            sudo_check "add VS Code repo"
            download "https://go.microsoft.com/fwlink/?LinkID=760868" /tmp/code.deb
            sudo dpkg -i /tmp/code.deb 2>/dev/null || sudo apt-get install -f -y -qq
            ;;
        dnf) sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
             sudo dnf install -y code 2>/dev/null || warn "VS Code not available via dnf";;
        pacman) pkg_install code visual-studio-code-bin 2>/dev/null || true;;
        *) warn "VS Code not handled for $PKG_MANAGER; install manually";;
    esac
    command -v code &>/dev/null && summary "  ✓ VS Code" || summary "  - VS Code (not installed)"
}

install_helix() { pkg_ensure helix helix-editor; command -v helix &>/dev/null && summary "  ✓ Helix" || summary "  - Helix (not installed)"; }
install_emacs() { pkg_ensure emacs; command -v emacs &>/dev/null && summary "  ✓ Emacs" || summary "  - Emacs (not installed)"; }

# ── DevOps & Cloud ──────────────────────────────────────────────────────────

install_docker() {
    header "Docker"
    if command -v docker &>/dev/null; then
        ok "Docker already installed"
        summary "  ✓ Docker"
        if ! docker compose version &>/dev/null 2>&1 && command -v docker-compose &>/dev/null; then
            ok "docker-compose plugin not found, but standalone present"
        fi
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping Docker"; summary "  - Docker (skipped — offline)"; return 0
    fi
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo_check "install Docker"
        download "https://get.docker.com" /tmp/get-docker.sh
        sh /tmp/get-docker.sh 2>&1 | tee -a "$LOG_FILE" >/dev/null
        sudo usermod -aG docker "$USER" 2>/dev/null || true
    else
        pkg_ensure docker docker-compose docker-buildx
    fi
    command -v docker &>/dev/null && summary "  ✓ Docker + Compose" || summary "  - Docker (not installed)"
}

install_k8s() {
    header "Kubernetes Tools"
    pkg_ensure kubectl || {
        [ "$offline" = 0 ] && {
            local ver=$(curl -sL https://dl.k8s.io/release/stable.txt 2>/dev/null || echo "v1.30.0")
            download "https://dl.k8s.io/release/$ver/bin/linux/amd64/kubectl" /tmp/kubectl
            chmod +x /tmp/kubectl
            sudo_check "install kubectl"
            sudo mv /tmp/kubectl /usr/local/bin/kubectl
        }
    }
    pkg_ensure helm || {
        [ "$offline" = 0 ] && {
            download "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" /tmp/get-helm.sh
            bash /tmp/get-helm.sh 2>&1 | tee -a "$LOG_FILE" >/dev/null
        }
    }
    # k9s via krew or direct
    command -v k9s &>/dev/null || {
        [ "$offline" = 0 ] && {
            local k9s_ver="v0.32.7"
            download "https://github.com/derailed/k9s/releases/download/$k9s_ver/k9s_Linux_amd64.tar.gz" /tmp/k9s.tar.gz
            tar -xzf /tmp/k9s.tar.gz -C /tmp k9s 2>/dev/null
            sudo_check "install k9s"
            sudo mv /tmp/k9s /usr/local/bin/k9s 2>/dev/null || true
        }
    }
    for tool in kubectl helm k9s; do
        command -v "$tool" &>/dev/null && summary "  ✓ $tool" || summary "  - $tool (not installed)"
    done
}

install_terraform() {
    header "Terraform"
    pkg_ensure terraform || {
        [ "$offline" = 0 ] && {
            download "https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip" /tmp/tf.zip
            unzip -qo /tmp/tf.zip -d /tmp terraform 2>/dev/null
            sudo_check "install terraform"
            sudo mv /tmp/terraform /usr/local/bin/terraform 2>/dev/null || true
        }
    }
    command -v terraform &>/dev/null && summary "  ✓ Terraform" || summary "  - Terraform (not installed)"
}

install_aws_cli() {
    header "AWS CLI"
    if command -v aws &>/dev/null; then
        ok "AWS CLI already installed"
        summary "  ✓ AWS CLI"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping AWS CLI"; summary "  - AWS CLI (skipped — offline)"; return 0
    fi
    download "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" /tmp/awscliv2.zip
    unzip -qo /tmp/awscliv2.zip -d /tmp aws 2>/dev/null
    sudo_check "install AWS CLI"
    sudo /tmp/aws/install 2>&1 | tee -a "$LOG_FILE" >/dev/null
    command -v aws &>/dev/null && summary "  ✓ AWS CLI" || summary "  - AWS CLI (not installed)"
}

install_gcloud() {
    header "Google Cloud CLI"
    command -v gcloud &>/dev/null && { ok "gcloud already installed"; summary "  ✓ gcloud"; return 0; }
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping gcloud"; summary "  - gcloud (skipped — offline)"; return 0
    fi
    case "$PKG_MANAGER" in
        apt)
            sudo_check "add gcloud repo"
            download "https://packages.cloud.google.com/apt/doc/apt-key.gpg" /tmp/gcloud-key.gpg
            sudo apt-key add /tmp/gcloud-key.gpg 2>/dev/null || true
            echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
            sudo apt-get update -qq 2>/dev/null || true
            pkg_install google-cloud-cli
            ;;
        dnf) pkg_install google-cloud-cli || warn "gcloud not available via dnf";;
        *) download "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz" /tmp/gcloud.tar.gz
           tar -xzf /tmp/gcloud.tar.gz -C /tmp 2>/dev/null
           bash /tmp/google-cloud-sdk/install.sh -q 2>&1 | tee -a "$LOG_FILE" >/dev/null
           sudo_check "symlink gcloud"
           sudo ln -sf /tmp/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud 2>/dev/null || true
           ;;
    esac
    command -v gcloud &>/dev/null && summary "  ✓ gcloud" || summary "  - gcloud (not installed)"
}

install_ansible() {
    header "Ansible"
    pkg_ensure ansible
    command -v ansible &>/dev/null && summary "  ✓ Ansible" || summary "  - Ansible (not installed)"
}

# ── CLI Utilities ───────────────────────────────────────────────────────────

install_cli_utils() {
    header "CLI Utilities"
    local utils=()
    for util in eza bat fzf ripgrep fd-find lazygit jq yq httpie; do
        if command -v "$util" &>/dev/null; then
            log "  ${DIM}✓ $util already installed${cN}"
            summary "  ✓ $util"
        else
            utils+=("$util")
        fi
    done
    if [ ${#utils[@]} -gt 0 ]; then
        pkg_install "${utils[@]}"
        for util in "${utils[@]}"; do
            command -v "$util" &>/dev/null && summary "  ✓ $util" || summary "  - $util (not installed)"
        done
    fi
    # zoxide
    if command -v zoxide &>/dev/null; then
        log "  ${DIM}✓ zoxide already installed${cN}"
        summary "  ✓ zoxide"
    elif [ "$offline" = 0 ]; then
        run_spinner "Installing zoxide..." \
            bash -c "download https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh /tmp/zoxide-install.sh && bash /tmp/zoxide-install.sh"
        command -v zoxide &>/dev/null && summary "  ✓ zoxide" || summary "  - zoxide (not installed)"
    fi
    # btm (bottom)
    if command -v btm &>/dev/null; then
        log "  ${DIM}✓ btm already installed${cN}"
        summary "  ✓ btm"
    else
        pkg_install bottom 2>/dev/null || pkg_install btm 2>/dev/null || true
        command -v btm &>/dev/null && summary "  ✓ btm" || summary "  - btm (not installed)"
    fi
}

# ── Databases ───────────────────────────────────────────────────────────────

install_databases() {
    header "Database Tools"
    pkg_ensure postgresql-client libpq-dev || true
    pkg_ensure redis-cli redis || true
    pkg_ensure sqlite3
    for db in psql redis-cli sqlite3; do
        command -v "$db" &>/dev/null && summary "  ✓ $db" || summary "  - $db (not installed)"
    done
}

# ── Version Control ─────────────────────────────────────────────────────────

install_git_latest() {
    header "Git (latest)"
    if command -v git &>/dev/null; then
        local ver=$(git --version 2>/dev/null | cut -d' ' -f3)
        ok "Git $ver already installed"
        summary "  ✓ Git $ver"
        return 0
    fi
    pkg_ensure git
    command -v git &>/dev/null && summary "  ✓ Git" || summary "  - Git (not installed)"
}

install_gh() {
    header "GitHub CLI"
    if command -v gh &>/dev/null; then
        ok "GitHub CLI already installed"
        summary "  ✓ GitHub CLI"
        return 0
    fi
    if [ "$offline" = 1 ]; then
        warn "Offline — skipping gh"; summary "  - GitHub CLI (skipped — offline)"; return 0
    fi
    case "$PKG_MANAGER" in
        apt)
            sudo_check "add GitHub CLI repo"
            download "https://cli.github.com/packages/githubcli-archive-keyring.gpg" /tmp/gh-key.gpg
            sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null < /tmp/gh-key.gpg 2>/dev/null || true
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
            sudo apt-get update -qq
            pkg_install gh
            ;;
        *) pkg_install gh || {
            download "https://github.com/cli/cli/releases/download/v2.63.2/gh_2.63.2_linux_amd64.tar.gz" /tmp/gh.tar.gz
            tar -xzf /tmp/gh.tar.gz -C /tmp gh_2.63.2_linux_amd64/bin/gh 2>/dev/null
            sudo_check "install gh"
            sudo mv /tmp/gh_2.63.2_linux_amd64/bin/gh /usr/local/bin/gh 2>/dev/null || true
        };;
    esac
    command -v gh &>/dev/null && summary "  ✓ GitHub CLI" || summary "  - GitHub CLI (not installed)"
}

# ── System Tweaks (Linux-only) ──────────────────────────────────────────────

apply_system_tweaks() {
    header "System Tweaks"
    [ "$IS_WSL" = 1 ] && { warn "WSL detected — skipping system tweaks"; return 0; }
    [ "$IS_LINUX" = 0 ] && { warn "Not Linux — skipping system tweaks"; return 0; }
    local tweaks_sel
    tweaks_sel=$(tui_checklist "System Tweaks" "Select tweaks to apply:" \
        "keyrate"  "Increase key repeat rate (faster typing)" OFF \
        "swappiness" "Reduce swappiness to 10" OFF \
        "esync"    "Enable esync/fsync limits for gaming" OFF \
        "inotify"  "Increase inotify watchers (Neovim/IDE)" OFF 2>&1)
    [ $? != 0 ] && { info "Tweaks cancelled."; return 0; }

    if echo "$tweaks_sel" | grep -q "keyrate"; then
        sudo_check "set key repeat rate"
        sudo tee /etc/udev/rules.d/99-keyboard.rules >/dev/null 2>/dev/null || true
        gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25 2>/dev/null || true
        gsettings set org.gnome.desktop.peripherals.keyboard delay 200 2>/dev/null || true
        ok "Key repeat rate increased"
        summary "  ✓ Key repeat rate"
    fi
    if echo "$tweaks_sel" | grep -q "swappiness"; then
        sudo_check "set swappiness"
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.d/99-swappiness.conf >/dev/null
        sudo sysctl -w vm.swappiness=10 2>/dev/null || true
        ok "Swappiness set to 10"
        summary "  ✓ Swappiness"
    fi
    if echo "$tweaks_sel" | grep -q "esync"; then
        sudo_check "set esync limits"
        echo -e "* soft nofile 524288\n* hard nofile 524288" | sudo tee /etc/security/limits.d/99-nofile.conf >/dev/null
        ok "File descriptor limits increased"
        summary "  ✓ esync/fsync limits"
    fi
    if echo "$tweaks_sel" | grep -q "inotify"; then
        sudo_check "increase inotify watchers"
        echo "fs.inotify.max_user_watches=524288" | sudo tee /etc/sysctl.d/99-inotify.conf >/dev/null
        sudo sysctl -w fs.inotify.max_user_watches=524288 2>/dev/null || true
        ok "Inotify watchers increased"
        summary "  ✓ Inotify watchers"
    fi
}

# ── Capture Package List ────────────────────────────────────────────────────

capture_package_list() {
    header "Capturing Package List"
    local out="$CONFIG_DIR/package-list-$(date +%Y%m%d-%H%M%S).txt"
    case "$PKG_MANAGER" in
        apt)    dpkg -l | awk '/^ii/ {print $2 "=" $3}' > "$out";;
        dnf)    dnf list installed 2>/dev/null | tail -n +2 | awk '{print $1}' > "$out";;
        pacman) pacman -Qe > "$out";;
        zypper) zypper se --installed-only 2>/dev/null | tail -n +5 | awk '{print $3}' > "$out";;
        apk)    apk info > "$out";;
        brew)   brew list --formula > "$out";;
        *)      warn "Don't know how to capture package list for $PKG_MANAGER"; return 1;;
    esac
    ok "Package list saved to $out ($(wc -l < "$out") packages)"
    echo "$out"
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN MENU
# ─────────────────────────────────────────────────────────────────────────────

dev_tools_menu() {
    header "Dev Tools Selection"

    local tools_sel
    tools_sel=$(tui_checklist "Dev Tools" "Select tools to install (SPACE to toggle, ENTER to confirm):" \
        "─── Languages & Runtimes ───" "" OFF \
        "nodejs"    "Node.js with nvm" OFF \
        "python"    "Python (pyenv + pipx)" OFF \
        "go"        "Go language" OFF \
        "rust"      "Rust (rustup)" OFF \
        "java"      "OpenJDK 17" OFF \
        "ruby"      "Ruby (rbenv)" OFF \
        "─── Terminal & Shell ───" "" OFF \
        "zsh"       "Zsh + Oh-My-Zsh + plugins" OFF \
        "starship"  "Starship prompt" OFF \
        "fish"      "Fish shell" OFF \
        "tmux"      "Tmux + TPM" OFF \
        "alacritty" "Alacritty terminal" OFF \
        "kitty"     "Kitty terminal" OFF \
        "─── Editors ───" "" OFF \
        "neovim"    "Neovim (latest)" OFF \
        "vscode"    "VS Code" OFF \
        "helix"     "Helix editor" OFF \
        "emacs"     "Emacs" OFF \
        "─── DevOps & Cloud ───" "" OFF \
        "docker"    "Docker + Compose" OFF \
        "k8s"       "Kubernetes tools (kubectl, helm, k9s)" OFF \
        "terraform" "Terraform" OFF \
        "aws"       "AWS CLI" OFF \
        "gcloud"    "Google Cloud CLI" OFF \
        "ansible"   "Ansible" OFF \
        "─── CLI Utilities ───" "" OFF \
        "cli_utils" "eza, bat, fzf, ripgrep, fd, lazygit, jq, yq, httpie, zoxide, btm" OFF \
        "─── Databases ───" "" OFF \
        "databases" "PostgreSQL client, Redis CLI, SQLite" OFF \
        "─── Git ───" "" OFF \
        "git"       "Git (latest)" OFF \
        "gh"        "GitHub CLI" OFF \
        2>&1)
    local rc=$?
    [ "$rc" != 0 ] && { info "Tools selection cancelled."; return 0; }

    save_config "tools" "$tools_sel"

    # Install selected tools
    for tool in $tools_sel; do
        case "$tool" in
            nodejs)    install_nodejs;;
            python)    install_python;;
            go)        install_go;;
            rust)      install_rust;;
            java)      install_java;;
            ruby)      install_ruby;;
            zsh)       install_zsh_omz;;
            starship)  install_starship;;
            fish)      install_fish;;
            tmux)      install_tmux;;
            alacritty) install_terminal alacritty;;
            kitty)     install_terminal kitty;;
            neovim)    install_neovim;;
            vscode)    install_vscode;;
            helix)     install_helix;;
            emacs)     install_emacs;;
            docker)    install_docker;;
            k8s)       install_k8s;;
            terraform) install_terraform;;
            aws)       install_aws_cli;;
            gcloud)    install_gcloud;;
            ansible)   install_ansible;;
            cli_utils) install_cli_utils;;
            databases) install_databases;;
            git)       install_git_latest;;
            gh)        install_gh;;
            *)         warn "Unknown tool: $tool";;
        esac
    done

    ok "Dev tools installation complete"
    append_history "tools: installed $tools_sel"
}

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

show_summary() {
    header "Installation Summary"
    echo -e "${cC}Log file:${cN} $LOG_FILE"
    echo -e "${cC}Config:${cN}   $CONFIG_FILE"
    echo ""
    if [ -s "$SUMMARY_FILE" ]; then
        echo -e "${cW}Installed:${cN}"
        sort -u "$SUMMARY_FILE" | while IFS= read -r line; do
            echo -e "  $line"
        done
    else
        echo -e "  ${cY}Nothing was installed.${cN}"
    fi
    echo ""
    echo -e "  ${cC}To repeat this setup later:${cN} bash setup.sh --repeat"
    echo -e "  ${cC}To install dotfiles only:${cN}   bash setup.sh --dotfiles-only"
    echo -e "  ${cC}To install tools only:${cN}     bash setup.sh --tools-only"
    echo ""
    # Also try to show in dialog if we can
    if [ -s "$SUMMARY_FILE" ]; then
        local summary_text="Log: $LOG_FILE\n\nInstalled:\n$(sort -u "$SUMMARY_FILE")"
        tui_msgbox "Setup Complete" "$summary_text\n\nCheck the terminal for full details." 2>/dev/null || true
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: bash setup.sh [OPTIONS]

Options:
  --dotfiles-only    Only manage dotfiles (skip dev tools)
  --tools-only       Only install dev tools (skip dotfiles)
  --repeat           Re-run with previous selections
  --offline          Offline mode (skip downloads, install from cache/package manager)
  --force            Overwrite without confirmation
  --help             Show this help

Config: $CONFIG_FILE
Logs:   $LOG_FILE
EOF
    exit 0
}

# Parse flags
while [ $# -gt 0 ]; do
    case "$1" in
        --dotfiles-only) dotfiles_only=1;;
        --tools-only)    tools_only=1;;
        --repeat)        repeat=1;;
        --offline)       offline=1;;
        --force)         force=1;;
        --help|-h)       usage;;
        *)               err "Unknown option: $1"; usage;;
    esac
    shift
done

main() {
    # Banner
    echo -e "${cM}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║       Dotfiles & Dev Tools Setup v2.0            ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${cN}"
    info "Package manager: ${cC}$PKG_MANAGER${cN}"
    info "WSL: ${cC}$([ "$IS_WSL" = 1 ] && echo yes || echo no)${cN}"
    info "Log: $LOG_FILE"
    echo ""

    tui_init

    # Repeat mode
    if [ "$repeat" = 1 ]; then
        if [ -f "$CONFIG_FILE" ]; then
            info "Re-running with saved selections from $CONFIG_FILE"
        else
            warn "No saved config found at $CONFIG_FILE — starting fresh"
        fi
    fi

    # Run selected parts
    if [ "$dotfiles_only" = 1 ]; then
        run_dotfiles
    elif [ "$tools_only" = 1 ]; then
        dev_tools_menu
    else
        # Interactive main menu
        while true; do
            local choice
            choice=$(tui_menu "Dotfiles Setup" \
                "Choose an option:\n\n${cDIM}$(uname -o) | ${PKG_MANAGER} | ${cN}${cC}$([ "$offline" = 1 ] && echo 'OFFLINE' || echo 'ONLINE')${cN}" \
                "dotfiles" "Install / update dotfiles" \
                "tools"    "Install development tools" \
                "system"   "System tweaks (Linux only)" \
                "capture"  "Capture current package list" \
                "repeat"   "Save & re-run later" \
                "exit"     "Exit" 2>&1)
            local rc=$?
            [ "$rc" != 0 ] && break

            case "$choice" in
                dotfiles) run_dotfiles;;
                tools)    dev_tools_menu;;
                system)   apply_system_tweaks;;
                capture)  capture_package_list;;
                repeat)
                    save_value "meta" "last_run" "$(date +%Y-%m-%d_%H:%M)"
                    save_value "meta" "pkg_manager" "$PKG_MANAGER"
                    save_value "meta" "wsl" "$IS_WSL"
                    tui_msgbox "Saved" "Configuration saved to $CONFIG_FILE\nRun 'bash setup.sh --repeat' to re-run with these settings."
                    info "Config saved to $CONFIG_FILE"
                    ;;
                exit) break;;
            esac
        done
    fi

    # Summary
    show_summary

    # Copy log to latest
    cp "$LOG_FILE" "$LOG_FILE_LATEST" 2>/dev/null || true

    info "Done! Log: $LOG_FILE"
}

main
