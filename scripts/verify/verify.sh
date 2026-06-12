#!/usr/bin/env bash

declare -a VERIFIED_PKGS
declare -a MISSING_PKGS

verify_command() {
    local cmd="$1"
    local name="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        VERIFIED_PKGS+=("$name")
        return 0
    else
        MISSING_PKGS+=("$name")
        return 1
    fi
}

verify_all() {
    draw_section "SYSTEM VERIFICATION"

    VERIFIED_PKGS=()
    MISSING_PKGS=()

    local checks=(
        "git:git"
        "nvim:neovim"
        "zsh:zsh"
        "bash:bash"
        "curl:curl"
        "stow:stow"
        "fastfetch:fastfetch"
        "docker:docker"
        "node:nodejs"
        "npm:npm"
        "rustc:rust"
        "go:golang"
        "python3:python"
        "pip3:pip"
        "kitty:kitty"
        "tmux:tmux"
        "fzf:fzf"
        "bat:bat"
        "rg:ripgrep"
        "fd:fd-find"
    )

    for check in "${checks[@]}"; do
        local cmd="${check%%:*}"
        local name="${check##*:}"
        verify_command "$cmd" "$name"
    done

    verify_command "starship" "starship"

    if command -v virsh &>/dev/null; then
        VERIFIED_PKGS+=("kvm")
    else
        MISSING_PKGS+=("kvm")
    fi

    if command -v brave-browser &>/dev/null || command -v brave &>/dev/null; then
        VERIFIED_PKGS+=("brave")
    else
        MISSING_PKGS+=("brave")
    fi

    echo
    printf "  ${GREEN}✓${RESET} %-20s %s\n" "Verified:" "${#VERIFIED_PKGS[@]} tools"
    if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
        printf "  ${RED}✗${RESET} %-20s %s\n" "Missing:" "${#MISSING_PKGS[@]} tools"
        for pkg in "${MISSING_PKGS[@]}"; do
            printf "    - %s\n" "$pkg"
        done
    fi
    echo

    log_info "Verification: ${#VERIFIED_PKGS[@]} found, ${#MISSING_PKGS[@]} missing"
}

verify_dotfiles() {
    local stow_dir="${DOTFILES_DIR}/stow"
    local verified=0
    local missing=0

    for package_dir in "$stow_dir"/*/; do
        [[ ! -d "$package_dir" ]] && continue

        while IFS= read -r -d '' file; do
            local rel_path="${file#$package_dir}"
            local target="$HOME/$rel_path"
            if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$file" ]]; then
                verified=$((verified + 1))
            else
                missing=$((missing + 1))
                log_debug "Missing link: ~/${rel_path}"
            fi
        done < <(find "$package_dir" -type f -print0 2>/dev/null)
    done

    log_info "Dotfile verification: ${verified} linked, ${missing} broken"
    STATS_CONFIGS=$verified
}

verify_services() {
    local services_enabled=0

    if command -v systemctl &>/dev/null; then
        for svc in docker libvirtd firewalld; do
            if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
                services_enabled=$((services_enabled + 1))
            fi
        done
    fi

    STATS_SERVICES=$services_enabled
    log_info "Services enabled: ${services_enabled}"
}

generate_report() {
    local total_errors=0
    [[ ${#MISSING_PKGS[@]} -gt 0 ]] && total_errors=${#MISSING_PKGS[@]}
    STATS_ERRORS=$total_errors

    echo
    echo -e "${MAGENTA_BOLD}════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA_BOLD}         INSTALLATION COMPLETE${RESET}"
    echo -e "${MAGENTA_BOLD}════════════════════════════════════════════════${RESET}"
    echo
    printf "  ${BOLD}%-25s${RESET} : ${CYAN}%s${RESET}\n" "Packages Installed" "${STATS_PACKAGES:-0}"
    printf "  ${BOLD}%-25s${RESET} : ${CYAN}%s${RESET}\n" "Configs Linked" "${STATS_CONFIGS:-0}"
    printf "  ${BOLD}%-25s${RESET} : ${CYAN}%s${RESET}\n" "Services Enabled" "${STATS_SERVICES:-0}"
    printf "  ${BOLD}%-25s${RESET} : ${GREEN}%s${RESET}\n" "Errors" "${STATS_ERRORS:-0}"
    echo
    echo -e "${MAGENTA_BOLD}════════════════════════════════════════════════${RESET}"

    echo "" >>"$LOG_FILE"
    echo "═════════════════════════════════════════" >>"$LOG_FILE"
    echo "FINAL REPORT" >>"$LOG_FILE"
    echo "Packages: ${STATS_PACKAGES:-0}" >>"$LOG_FILE"
    echo "Configs:  ${STATS_CONFIGS:-0}" >>"$LOG_FILE"
    echo "Services: ${STATS_SERVICES:-0}" >>"$LOG_FILE"
    echo "Errors:   ${STATS_ERRORS:-0}" >>"$LOG_FILE"
    echo "═════════════════════════════════════════" >>"$LOG_FILE"

    if [[ ${STATS_ERRORS:-0} -gt 0 ]]; then
        echo
        echo -e "  ${YELLOW}Some items need attention. Check the log:${RESET}"
        echo -e "  ${CYAN}${LOG_FILE}${RESET}"
    fi
}

run_verification() {
    verify_all
    verify_dotfiles
    verify_services
    generate_report
}
