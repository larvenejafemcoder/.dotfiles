#!/usr/bin/env bash
# ── USMI Developer Workstation Bootstrap ──
# Fresh Linux Install → git clone → ./bootstrap.sh → Choose → Ready
set -euo pipefail

USMI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export USMI_DIR

source "$USMI_DIR/scripts/common.sh"
source "$USMI_DIR/scripts/detect.sh"
source "$USMI_DIR/scripts/install.sh"
source "$USMI_DIR/scripts/verify.sh"

source "$USMI_DIR/modules/ai.sh"
source "$USMI_DIR/modules/docker.sh"
source "$USMI_DIR/modules/virtualization.sh"
source "$USMI_DIR/modules/ide.sh"
source "$USMI_DIR/modules/dotfiles.sh"

# ── Assets ────────────────────────────────────────────────────────────────

SPLASH="
${CYAN_BOLD}
   ██╗   ██╗███████╗███╗   ███╗██╗
   ██║   ██║██╔════╝████╗ ████║██║
   ██║   ██║███████╗██╔████╔██║██║
   ██║   ██║╚════██║██║╚██╔╝██║██║
   ╚██████╔╝███████║██║ ╚═╝ ██║██║
    ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝
${RESET}
${CYAN_BOLD}  Universal System Machine Interface${RESET}
${DIM}  Developer Workstation Bootstrap${RESET}
"

# ── Phase 1: Core Loader ──────────────────────────────────────────────────

phase_detect() {
    clear
    echo -e "$SPLASH"
    echo
    log_step 1 7 "Hardware Detection"
    print_system_info
}

# ── Phase 2: Workload Selection ──────────────────────────────────────────

phase_menu() {
    while true; do
        clear
        echo -e "$SPLASH"
        draw_section "SELECT WORKLOAD"

        echo "  ${GREEN}[1]${RESET}  Web Development        ${DIM}Node.js, npm, pnpm, bun, yarn${RESET}"
        echo "  ${GREEN}[2]${RESET}  AI Development          ${DIM}Python, Ollama, CUDA, Jupyter${RESET}"
        echo "  ${GREEN}[3]${RESET}  C/C++ Systems           ${DIM}GCC, Clang, LLVM, CMake, GDB${RESET}"
        echo "  ${GREEN}[4]${RESET}  Rust Development        ${DIM}Rustup, rust-analyzer, cargo${RESET}"
        echo "  ${GREEN}[5]${RESET}  Game Development        ${DIM}Godot, Steam, Wine, Lutris${RESET}"
        echo "  ${GREEN}[6]${RESET}  Homelab Server          ${DIM}Docker, KVM, Nginx, Redis${RESET}"
        echo "  ${GREEN}[7]${RESET}  DevOps & Cloud          ${DIM}K8s, Terraform, Ansible, Helm${RESET}"
        echo "  ${GREEN}[8]${RESET}  Cybersecurity           ${DIM}Nmap, Wireshark, Metasploit${RESET}"
        echo
        echo "  ${YELLOW}[9]${RESET}  Full Workstation        ${DIM}Everything${RESET}"
        echo "  ${RED}[0]${RESET}  Exit"
        echo
        read -rp "  Select workload: " choice

        case "$choice" in
            1) install_workload "web" "Web Development"; break ;;
            2) install_workload "ai" "AI Development"; break ;;
            3) install_workload "cpp" "C/C++ Systems"; break ;;
            4) install_workload "rust" "Rust Development"; break ;;
            5) install_workload "game" "Game Development"; break ;;
            6) install_workload "homelab" "Homelab Server"; break ;;
            7) install_workload "devops" "DevOps & Cloud"; break ;;
            8) install_workload "cyber" "Cybersecurity"; break ;;
            9)
                for profile in web ai cpp rust game homelab devops; do
                    install_workload "$profile" "${profile^}"
                done
                break
                ;;
            0)
                echo -e "\n  ${YELLOW}Exiting.${RESET}\n"
                exit 0
                ;;
            *)
                echo -e "  ${RED}Invalid selection${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ── Phase 3-4: Package Installation ──────────────────────────────────────

install_workload() {
    local profile="$1"
    local name="$2"

    clear
    echo -e "$SPLASH"
    echo
    log_step 2 7 "Package Verification"

    pkg_update
    echo

    log_step 3 7 "Development Toolchain"
    install_profile "$profile"
    echo
}

# ── Phase 5: Config Deployment ───────────────────────────────────────────

phase_configs() {
    clear
    echo -e "$SPLASH"
    echo
    log_step 5 7 "Dotfile Synchronization"

    populate_configs_from_existing
    deploy_all
    create_dev_directories
    setup_git_config
    setup_ssh
    echo
}

# ── Phase 6: AI Runtime (if AI selected) ─────────────────────────────────

phase_ai() {
    if [[ "${HAS_OLLAMA:-}" == "true" ]] || [[ "${INSTALLED_AI:-}" == "true" ]]; then
        clear
        echo -e "$SPLASH"
        echo
        log_step 4 7 "AI Runtime Deployment"
        ai_menu
        echo
    fi
}

# ── Phase 7: Virtualization / Docker ──────────────────────────────────────

phase_virtualization() {
    clear
    echo -e "$SPLASH"
    echo
    log_step 6 7 "Virtualization Stack"

    if is_installed docker; then
        setup_docker
    fi

    if is_installed virsh; then
        setup_kvm
    fi

    docker_menu
    homelab_menu
    ide_menu
    echo
}

# ── Phase 8-9: Post Install ──────────────────────────────────────────────

phase_post() {
    clear
    echo -e "$SPLASH"
    echo
    log_step 7 7 "System Validation"
    verify_all
    post_install_summary

    if command -v fastfetch &>/dev/null; then
        echo
        fastfetch 2>/dev/null || true
    fi

    echo -e "${GREEN_BOLD}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║     System Ready — USMI Complete     ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${RESET}"
    echo
    echo -e "  ${YELLOW}Reload shell:${RESET} exec \$SHELL"
    echo
}

# ── Main ──────────────────────────────────────────────────────────────────

main() {
    if [[ "$(id -u)" -eq 0 ]]; then
        echo -e "${RED}Do not run as root. USMI uses sudo when needed.${RESET}"
        exit 1
    fi

    if ! command -v sudo &>/dev/null; then
        echo -e "${RED}sudo required but not found.${RESET}"
        exit 1
    fi

    phase_detect
    sleep 1

    phase_menu
    phase_configs

    INSTALLED_AI=false
    if [[ -f "$USMI_DIR/manifests/ai.conf" ]]; then
        while IFS= read -r line; do
            line="${line%%#*}"
            line="${line// /}"
            [[ -z "$line" ]] && continue
            [[ "$line" == "ollama" ]] || [[ "$line" == "python" ]] || [[ "$line" == "cuda" ]] && INSTALLED_AI=true
        done < "$USMI_DIR/manifests/ai.conf"
    fi

    phase_ai
    phase_virtualization
    phase_post
}

main "$@"
