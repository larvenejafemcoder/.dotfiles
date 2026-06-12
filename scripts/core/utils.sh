#!/usr/bin/env bash

is_installed() {
    command -v "$1" &>/dev/null
}

is_package_installed() {
    local pkg="$1"
    case "${DISTRO}" in
        arch|endeavouros) pacman -Qi "$pkg" &>/dev/null ;;
        ubuntu|debian) dpkg -s "$pkg" &>/dev/null 2>&1 ;;
        fedora) rpm -q "$pkg" &>/dev/null ;;
        opensuse) rpm -q "$pkg" &>/dev/null ;;
        *) return 1 ;;
    esac
}

backup_file() {
    local src="$1"
    local backup_dir="${BACKUP_DIR:-$HOME/.backup-$(date +%Y-%m-%d)}"
    if [[ ! -e "$src" ]]; then
        return 0
    fi
    if [[ -L "$src" ]]; then
        log_debug "Skipping backup of symlink: $src"
        return 0
    fi
    mkdir -p "$backup_dir"
    local dest="$backup_dir/$(echo "$src" | sed "s|^/home/||;s|/|_|g")"
    cp -r "$src" "$dest" 2>/dev/null || true
    log_info "Backed up: $src → $dest"
}

create_symlink() {
    local source="$1"
    local target="$2"
    if [[ ! -e "$source" ]]; then
        log_error "Source does not exist: $source"
        return 1
    fi
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        log_debug "Symlink already correct: $target"
        return 0
    fi
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        backup_file "$target"
        rm -rf "$target"
    fi
    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    log_success "Linked: $target → $source"
}

verify_symlink() {
    local target="$1"
    if [[ -L "$target" ]] && [[ -e "$target" ]]; then
        return 0
    fi
    return 1
}

run_with_spinner() {
    local msg="$1"
    shift
    local pid
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: $*"
        return 0
    fi
    "$@" &
    pid=$!
    spinner_start "$pid" "$msg"
    wait "$pid" 2>/dev/null
    return $?
}

run_with_progress() {
    local total="$1"
    local current="$2"
    local msg="$3"
    local percent=$((current * 100 / total))
    draw_progress_bar "$percent"
    echo -e "\n  ${CYAN}◆${RESET} $msg"
}

confirm_step() {
    local step="$1"
    local desc="$2"
    echo
    echo -e "${YELLOW}◆ Step ${step}:${RESET} ${BOLD}$desc${RESET}"
    if [[ "$UNATTENDED" == "true" ]]; then
        return 0
    fi
    local response
    read -rp "  Proceed? [Y/n]: " response
    [[ "$response" =~ ^[Nn] ]] && return 1
    return 0
}

require_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        log_warn "Running as root. Some operations may behave differently."
        return 0
    fi
    if ! command -v sudo &>/dev/null; then
        log_error "sudo is required but not installed"
        exit 1
    fi
}

collect_stats() {
    STATS_PACKAGES=0
    STATS_CONFIGS=0
    STATS_SERVICES=0
    STATS_ERRORS=0
}
