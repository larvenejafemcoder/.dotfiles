#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

for lib in "$DOTFILES_DIR/scripts/core"/*.sh; do
    source "$lib"
done

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

DRY_RUN=false
UNATTENDED=false
ROLLBACK_MODE=false
DEBUG=false
INSTALL_THEME=true
INSTALL_FONTS=true
INSTALL_STARSHIP=true
INSTALL_ZSH=true
INSTALL_RICE=false
INSTALL_DEV=true
INSTALL_DOCKER=true
INSTALL_KVM=true
INSTALL_DESKTOP=true
INSTALL_NEOVIM=true
INSTALL_BRAVE=true
INSTALL_SSH=true
MINIMAL=false
DESKTOP_PROFILE="default"
GIT_USERNAME="${GIT_USERNAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tui)
                exec "$DOTFILES_DIR/tui.sh"
                ;;
            --dry-run) DRY_RUN=true ;;
            --unattended) UNATTENDED=true ;;
            --rollback) ROLLBACK_MODE=true ;;
            --debug) DEBUG=true ;;
            --minimal)
                MINIMAL=true
                INSTALL_THEME=false
                INSTALL_FONTS=false
                INSTALL_STARSHIP=false
                INSTALL_ZSH=false
                INSTALL_DEV=false
                INSTALL_DOCKER=false
                INSTALL_KVM=false
                INSTALL_DESKTOP=false
                INSTALL_NEOVIM=false
                INSTALL_BRAVE=false
                INSTALL_SSH=false
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
                shift
                DESKTOP_PROFILE="$1"
                ;;
            --git-name)
                shift
                GIT_USERNAME="$1"
                ;;
            --git-email)
                shift
                GIT_EMAIL="$1"
                ;;
            --help|-h)
                echo "Usage: ./install.sh [OPTIONS]"
                echo ""
                echo "General:"
                echo "  --tui               Interactive TUI (Textual-based)" 
                echo "  --dry-run           Simulate without making changes"
                echo "  --unattended        No prompts, full automation"
                echo "  --rollback          Roll back previous deployment"
                echo "  --debug             Enable verbose debug output"
                echo ""
                echo "Profiles:"
                echo "  --minimal           Config symlinks only"
                echo "  --profile hyprland  Hyprland environment"
                echo "  --profile i3        i3 environment"
                echo "  --rice              Gruvbox ricing (themes, icons, wallpaper)"
                echo ""
                echo "Skips:"
                echo "  --no-theme          Skip theme installation"
                echo "  --no-fonts          Skip font installation"
                echo "  --no-starship       Skip Starship prompt"
                echo "  --no-zsh            Skip Zsh/Oh My Zsh"
                echo "  --no-dev            Skip developer tools"
                echo "  --no-docker         Skip Docker setup"
                echo "  --no-kvm            Skip KVM/QEMU setup"
                echo "  --no-desktop        Skip desktop environment"
                echo "  --no-neovim         Skip Neovim setup"
                echo "  --no-brave          Skip Brave browser"
                echo "  --no-ssh            Skip SSH key generation"
                echo ""
                echo "Git config (optional):"
                echo "  --git-name 'Name'   Git user name"
                echo "  --git-email 'email' Git user email"
                echo ""
                echo "Env vars:"
                echo "  GIT_USERNAME         Git user name"
                echo "  GIT_EMAIL            Git user email"
                echo "  DESKTOP_PROFILE      Desktop profile (hyprland|i3)"
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

declare -A DEPLOY_STATUS
init_status() {
    DEPLOY_STATUS=( ["Detection"]="pending" ["Packages"]="pending" ["Dotfiles"]="pending" ["Shell"]="pending" ["Dev Tools"]="pending" ["Fonts"]="pending" ["Docker"]="pending" ["KVM"]="pending" ["Desktop"]="pending" ["Themes"]="pending" ["Neovim"]="pending" ["Brave"]="pending" ["SSH Keys"]="pending" ["Verification"]="pending" )
}

update_status() {
    local key="$1"
    local value="$2"
    DEPLOY_STATUS["$key"]="$value"
}

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
