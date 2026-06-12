#!/usr/bin/env bash
# ── USMI Phase 10: System Validation ──
# Verifies installation and generates report

VERIFIED=()
MISSING=()

check_tool() {
    local cmd="$1"
    local name="${2:-$cmd}"
    if command -v "$cmd" &>/dev/null; then
        VERIFIED+=("$name")
        return 0
    else
        MISSING+=("$name")
        return 1
    fi
}

check_service() {
    local service="$1"
    if command -v systemctl &>/dev/null; then
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

print_check() {
    local status="$1"
    local name="$2"
    if [[ "$status" == "ok" ]]; then
        printf "  ${GREEN}✓${RESET} %-25s\n" "$name"
    else
        printf "  ${DIM}·${RESET} %-25s\n" "$name"
    fi
}

verify_all() {
    draw_section "SYSTEM VALIDATION"

    VERIFIED=()
    MISSING=()

    local tools=("git" "gcc" "g++" "make" "cmake" "python3" "node" "npm" "rustc" "go" "docker" "nvim" "tmux" "zsh" "curl" "wget" "rg" "fzf" "btop" "ollama" "kubectl" "terraform" "ansible" "vagrant" "virsh" "nmap" "socat" "btop" "fastfetch" "lazygit" "bat")

    echo -e "  ${BOLD}Tools:${RESET}"
    for tool in "${tools[@]}"; do
        if check_tool "$tool"; then
            print_check "ok" "$tool"
        else
            print_check "no" "$tool"
        fi
    done

    echo
    echo -e "  ${BOLD}Services:${RESET}"
    for svc in docker libvirtd sshd; do
        if check_service "$svc"; then
            print_check "ok" "$svc"
        else
            print_check "no" "$svc"
        fi
    done

    local total=${#VERIFIED[@]}
    local missing=${#MISSING[@]}
    echo
    echo -e "  ${GREEN}✓${RESET} ${total} tools found"
    [[ $missing -gt 0 ]] && echo -e "  ${YELLOW}○${RESET} ${missing} not installed"
    echo

    printf "  ${BOLD}%-25s${RESET} : ${CYAN}%s${RESET}\n" "Tools Installed" "$total"
    [[ $missing -gt 0 ]] && printf "  ${BOLD}%-25s${RESET} : ${YELLOW}%s${RESET}\n" "Not Found" "$missing"
    echo
}

post_install_summary() {
    draw_section "POST-INSTALL CHECKLIST"
    local items=(
        "Docker enabled"
        "SSH configured"
        "Git configured"
        "Dotfiles copied"
        "Development folders created"
        "Fastfetch installed"
        "Neovim installed"
    )

    for item in "${items[@]}"; do
        case "$item" in
            "Docker enabled")        check_tool "docker" && echo -e "  ${GREEN}✓${RESET} ${item}" || echo -e "  ${DIM}·${RESET} ${item}" ;;
            "Git configured")        check_tool "git" && echo -e "  ${GREEN}✓${RESET} ${item}" || echo -e "  ${DIM}·${RESET} ${item}" ;;
            "Dotfiles copied")       [[ -d "$HOME/.config/nvim" ]] && echo -e "  ${GREEN}✓${RESET} ${item}" || echo -e "  ${DIM}·${RESET} ${item}" ;;
            "Development folders created") [[ -d "$HOME/Development" ]] && echo -e "  ${GREEN}✓${RESET} ${item}" || echo -e "  ${DIM}·${RESET} ${item}" ;;
            "Fastfetch installed")   check_tool "fastfetch" && echo -e "  ${GREEN}✓${RESET} ${item}" || echo -e "  ${DIM}·${RESET} ${item}" ;;
            "Neovim installed")      check_tool "nvim" && echo -e "  ${GREEN}✓${RESET} ${item}" || echo -e "  ${DIM}·${RESET} ${item}" ;;
            "SSH configured")        [[ -f "$HOME/.ssh/id_ed25519" ]] && echo -e "  ${GREEN}✓${RESET} ${item}" || echo -e "  ${DIM}·${RESET} ${item}" ;;
            *)                       echo -e "  ${DIM}·${RESET} ${item}" ;;
        esac
    done
    echo
}
