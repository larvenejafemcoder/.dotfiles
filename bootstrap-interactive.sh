#!/usr/bin/env bash
# ── USMI Developer Workstation Bootstrap ──
# Interactive universal Linux installer with component selection
# Usage: ./bootstrap-interactive.sh [--help]
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

for lib in "$DOTFILES_DIR/scripts/core"/*.sh; do source "$lib"; done
source "$DOTFILES_DIR/scripts/pkg/manager.sh"

if [[ -f "$DOTFILES_DIR/scripts/setup/dev.sh" ]]; then source "$DOTFILES_DIR/scripts/setup/dev.sh"; fi
if [[ -f "$DOTFILES_DIR/scripts/setup/docker.sh" ]]; then source "$DOTFILES_DIR/scripts/setup/docker.sh"; fi
if [[ -f "$DOTFILES_DIR/scripts/setup/kvm.sh" ]]; then source "$DOTFILES_DIR/scripts/setup/kvm.sh"; fi
if [[ -f "$DOTFILES_DIR/scripts/setup/neovim.sh" ]]; then source "$DOTFILES_DIR/scripts/setup/neovim.sh"; fi
if [[ -f "$DOTFILES_DIR/scripts/setup/brave.sh" ]]; then source "$DOTFILES_DIR/scripts/setup/brave.sh"; fi
if [[ -f "$DOTFILES_DIR/scripts/setup/fonts.sh" ]]; then source "$DOTFILES_DIR/scripts/setup/fonts.sh"; fi
if [[ -f "$DOTFILES_DIR/scripts/setup/shell.sh" ]]; then source "$DOTFILES_DIR/scripts/setup/shell.sh"; fi
if [[ -f "$DOTFILES_DIR/scripts/verify/verify.sh" ]]; then source "$DOTFILES_DIR/scripts/verify/verify.sh"; fi

DRY_RUN=false
UNATTENDED=false
DEBUG=false
SKIP_CONFIRM=false
SELECTED=()
LOG_FILE="${LOG_FILE:-$HOME/.local/share/dotfiles/bootstrap.log}"

# ── Banner ────────────────────────────────────────────────────────────────

show_banner() {
    clear
    echo -e "${CYAN_BOLD}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║       USMI Developer Workstation Bootstrap       ║"
    echo "║           Universal Linux Installer              ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${BOLD}Detected OS:${RESET} ${CYAN}${DISTRO^}${RESET}"
    echo -e "  ${BOLD}Hostname:${RESET}   ${CYAN}${HOSTNAME}${RESET}"
    echo -e "  ${BOLD}Kernel:${RESET}     ${CYAN}$(uname -r)${RESET}"
    echo
}

# ── Menu ──────────────────────────────────────────────────────────────────

show_menu() {
    show_banner
    echo -e "${BLUE_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    echo -e "  ${BOLD}Select Components to Install:${RESET}"
    echo
    echo -e "  ${GREEN}[1]${RESET}  ${BOLD}Development Essentials${RESET}      ${DIM}(git, gcc, cmake, python, node, neovim, tmux, zsh, tools)${RESET}"
    echo -e "  ${GREEN}[2]${RESET}  ${BOLD}AI Development${RESET}              ${DIM}(Ollama, PyTorch, transformers, accelerate)${RESET}"
    echo -e "  ${GREEN}[3]${RESET}  ${BOLD}Systems Programming${RESET}         ${DIM}(Rust, Go, Zig, Clang/LLVM, GDB)${RESET}"
    echo -e "  ${GREEN}[4]${RESET}  ${BOLD}Web Development${RESET}             ${DIM}(Node, npm, pnpm, bun, yarn)${RESET}"
    echo -e "  ${GREEN}[5]${RESET}  ${BOLD}DevOps & Cloud${RESET}              ${DIM}(Docker, K8s, Terraform, Ansible)${RESET}"
    echo -e "  ${GREEN}[6]${RESET}  ${BOLD}Virtualization & Homelab${RESET}    ${DIM}(KVM, QEMU, Virt-Manager, Vagrant)${RESET}"
    echo -e "  ${GREEN}[7]${RESET}  ${BOLD}Security & Networking${RESET}       ${DIM}(Tailscale, nmap, wireshark, iperf3)${RESET}"
    echo -e "  ${GREEN}[8]${RESET}  ${BOLD}Desktop Applications${RESET}        ${DIM}(Brave, VSCode, Obsidian, kitty)${RESET}"
    echo -e "  ${GREEN}[9]${RESET}  ${BOLD}Shell & Dotfiles${RESET}            ${DIM}(Zsh, Oh My Zsh, Starship, fonts, dotfiles)${RESET}"
    echo
    echo -e "${BLUE_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${YELLOW}[a]${RESET}  ${BOLD}Install Everything${RESET}"
    echo -e "  ${RED}[0]${RESET}  ${BOLD}Exit${RESET}"
    echo
    echo -e "  ${DIM}Enter numbers separated by spaces (e.g. '1 3 5') or 'a' for all${RESET}"
    echo
}

get_category_name() {
    case "$1" in
        1) echo "Development Essentials" ;;
        2) echo "AI Development" ;;
        3) echo "Systems Programming" ;;
        4) echo "Web Development" ;;
        5) echo "DevOps & Cloud" ;;
        6) echo "Virtualization & Homelab" ;;
        7) echo "Security & Networking" ;;
        8) echo "Desktop Applications" ;;
        9) echo "Shell & Dotfiles" ;;
    esac
}

get_packages_by_category() {
    local cat="$1"
    case "$cat" in
        1)
            case "${DISTRO}" in
                arch) echo "base-devel git gcc clang cmake ninja gdb make python python-pip nodejs npm neovim tmux zsh curl wget ripgrep fd fzf btop fastfetch stow bat eza zoxide jq tree unzip lazygit python-pipx" ;;
                ubuntu|debian) echo "build-essential git gcc clang cmake ninja-build gdb make python3 python3-pip python3-venv nodejs npm neovim tmux zsh curl wget ripgrep fd-find fzf btop fastfetch stow bat eza zoxide jq tree unzip lazygit pipx" ;;
                fedora) echo "@development-tools git gcc clang cmake ninja-build gdb make python3 python3-pip nodejs npm neovim tmux zsh curl wget ripgrep fd-find fzf btop fastfetch stow bat eza zoxide jq tree unzip lazygit python3-pipx" ;;
                opensuse) echo "patterns-devel-base-devel git gcc clang cmake ninja gdb make python3 python3-pip nodejs npm neovim tmux zsh curl wget ripgrep fd fzf btop fastfetch stow bat eza zoxide jq tree unzip lazygit python3-pipx" ;;
            esac
            ;;
        2)
            echo "python python3-pip python-pipx"
            ;;
        3)
            case "${DISTRO}" in
                arch) echo "go zig rustup lldb valgrind gdb" ;;
                ubuntu|debian|fedora|opensuse) echo "golang zig rustup lldb valgrind gdb" ;;
            esac
            ;;
        4)
            echo "nodejs npm yarn"
            ;;
        5)
            case "${DISTRO}" in
                arch) echo "docker docker-compose kubectl helm minikube terraform ansible podman podman-docker" ;;
                ubuntu|debian) echo "docker.io docker-compose-v2 kubectl helm minikube terraform ansible podman" ;;
                fedora) echo "docker docker-compose kubectl helm minikube terraform ansible podman" ;;
                opensuse) echo "docker docker-compose kubectl helm minikube terraform ansible podman" ;;
            esac
            ;;
        6)
            case "${DISTRO}" in
                arch) echo "qemu-full libvirt virt-manager edk2-ovmf dnsmasq bridge-utils firewalld vagrant" ;;
                ubuntu|debian) echo "qemu-system-x86 qemu-utils libvirt-daemon-system virt-manager ovmf dnsmasq bridge-utils firewalld vagrant" ;;
                fedora) echo "qemu-kvm qemu-img libvirt virt-manager edk2-ovmf dnsmasq bridge-utils firewalld vagrant" ;;
                opensuse) echo "qemu-kvm qemu-img libvirt virt-manager edk2-ovmf dnsmasq bridge-utils firewalld vagrant" ;;
            esac
            ;;
        7)
            case "${DISTRO}" in
                arch) echo "nmap wireshark-qt socat iperf3 traceroute whois netcat-openbsd openbsd-netcat tk" ;;
                ubuntu|debian) echo "nmap wireshark socat iperf3 traceroute whois netcat-openbsd tk" ;;
                fedora) echo "nmap wireshark socat iperf3 traceroute whois nmap-ncat tk" ;;
                opensuse) echo "nmap wireshark socat iperf3 traceroute whoistk" ;;
            esac
            ;;
        8)
            echo ""
            ;;
        9)
            case "${DISTRO}" in
                arch) echo "zsh fish starship kitty alacritty stow dconf" ;;
                ubuntu|debian) echo "zsh fish starship kitty alacritty stow dconf-cli" ;;
                fedora) echo "zsh fish starship kitty alacritty stow dconf" ;;
                opensuse) echo "zsh fish starship kitty alacritty stow dconf" ;;
            esac
            ;;
    esac
}

# ── Phase Display ─────────────────────────────────────────────────────────

show_phase() {
    local num="$1"
    local total="$2"
    local desc="$3"
    echo
    echo -e "  ${BLUE_BOLD}[${num}/${total}]${RESET} ${BOLD}${desc}${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────${RESET}"
}

# ── Component Installers ─────────────────────────────────────────────────

install_ollama() {
    if command -v ollama &>/dev/null; then
        log_info "Ollama already installed"
        return 0
    fi
    log_info "Installing Ollama..."
    if curl -fsSL https://ollama.com/install.sh | sh &>/dev/null; then
        log_success "Ollama installed"
        log_info "Pull a model: ollama pull qwen3"
    else
        log_warn "Ollama install script failed. Install manually from ollama.com"
    fi
}

install_rust_toolchain() {
    if command -v rustc &>/dev/null; then
        log_info "Rust already installed: $(rustc --version)"
        return 0
    fi
    log_info "Installing Rust via rustup..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null; then
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env" 2>/dev/null || true
        log_success "Rust installed: $(rustc --version 2>/dev/null || true)"
    else
        log_warn "Rust install failed"
    fi
}

create_dev_workspace() {
    show_phase 1 1 "Creating Developer Workspace"
    mkdir -p "$HOME/Development"/{C,CPP,Rust,Python,Web,AI,Homelab,Docker,Go,Zig}
    log_success "~/Development/ directory structure created"
}

# ── Category Runner ──────────────────────────────────────────────────────

run_category() {
    local cat="$1"

    case "$cat" in
        1)
            show_phase 1 3 "Installing Development Essentials"
            local pkgs; pkgs=$(get_packages_by_category 1)
            # shellcheck disable=SC2086
            pkg_install_list $pkgs

            show_phase 2 3 "Setting Up Development Tools"
            if declare -F setup_development &>/dev/null; then
                setup_development
            fi
            if declare -F setup_neovim &>/dev/null; then
                setup_neovim
            fi

            show_phase 3 3 "Creating Developer Workspace"
            create_dev_workspace
            ;;

        2)
            show_phase 1 3 "Installing AI Dependencies"
            local pkgs; pkgs=$(get_packages_by_category 2)
            # shellcheck disable=SC2086
            pkg_install_list $pkgs

            show_phase 2 3 "Installing Python AI Libraries"
            if command -v pip3 &>/dev/null; then
                pip3 install --user --break-system-packages torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu &>/dev/null || \
                pip3 install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu &>/dev/null || true
                pip3 install --user --break-system-packages transformers accelerate sentencepiece &>/dev/null || \
                pip3 install --user transformers accelerate sentencepiece &>/dev/null || true
                log_success "Python AI libraries installed"
            fi

            show_phase 3 3 "Installing Ollama"
            install_ollama
            ;;

        3)
            show_phase 1 2 "Installing Systems Programming Tools"
            local pkgs; pkgs=$(get_packages_by_category 3)
            # shellcheck disable=SC2086
            pkg_install_list $pkgs

            show_phase 2 2 "Setting Up Rust Toolchain"
            install_rust_toolchain
            ;;

        4)
            show_phase 1 2 "Installing Web Development Tools"
            local pkgs; pkgs=$(get_packages_by_category 4)
            # shellcheck disable=SC2086
            pkg_install_list $pkgs

            show_phase 2 2 "Installing pnpm & Bun"
            if command -v npm &>/dev/null; then
                npm install -g pnpm &>/dev/null || true
                log_success "pnpm installed"
            fi
            if ! command -v bun &>/dev/null; then
                curl -fsSL https://bun.sh/install | bash &>/dev/null || true
                log_success "Bun installed"
            fi
            ;;

        5)
            show_phase 1 2 "Installing DevOps Packages"
            local pkgs; pkgs=$(get_packages_by_category 5)
            # shellcheck disable=SC2086
            pkg_install_list $pkgs

            show_phase 2 2 "Configuring Docker"
            if declare -F setup_docker &>/dev/null; then
                setup_docker
            else
                if command -v docker &>/dev/null; then
                    sudo systemctl enable --now docker 2>/dev/null || true
                    sudo usermod -aG docker "$USER" 2>/dev/null || true
                    log_success "Docker configured"
                fi
            fi
            ;;

        6)
            show_phase 1 2 "Installing Virtualization Packages"
            local pkgs; pkgs=$(get_packages_by_category 6)
            # shellcheck disable=SC2086
            pkg_install_list $pkgs

            show_phase 2 2 "Configuring KVM/QEMU"
            if declare -F setup_kvm &>/dev/null; then
                setup_kvm
            else
                if command -v virsh &>/dev/null; then
                    sudo systemctl enable --now libvirtd 2>/dev/null || true
                    sudo usermod -aG libvirt "$USER" 2>/dev/null || true
                    log_success "KVM configured"
                fi
            fi
            ;;

        7)
            show_phase 1 1 "Installing Security & Networking Tools"
            local pkgs; pkgs=$(get_packages_by_category 7)
            # shellcheck disable=SC2086
            pkg_install_list $pkgs
            if ! command -v tailscale &>/dev/null; then
                log_info "Tailscale: install from https://tailscale.com/download"
            fi
            ;;

        8)
            show_phase 1 1 "Installing Desktop Applications"
            if declare -F setup_brave &>/dev/null; then
                setup_brave
            fi
            if ! command -v code &>/dev/null; then
                log_info "VSCode: install from https://code.visualstudio.com/download"
            fi
            if ! command -v cursor &>/dev/null; then
                log_info "Cursor: install from https://cursor.sh"
            fi
            if ! command -v obsidian &>/dev/null; then
                log_info "Obsidian: install from https://obsidian.md/download"
            fi
            ;;

        9)
            show_phase 1 3 "Installing Shell Environment"
            local pkgs; pkgs=$(get_packages_by_category 9)
            # shellcheck disable=SC2086
            pkg_install_list $pkgs

            show_phase 2 3 "Setting Up Shell"
            if declare -F setup_shell &>/dev/null; then
                setup_shell
            fi
            if declare -F setup_fonts &>/dev/null; then
                setup_fonts
            fi

            show_phase 3 3 "Deploying Dotfiles"
            if [[ -f "$DOTFILES_DIR/scripts/dotfiles/deploy.sh" ]]; then
                source "$DOTFILES_DIR/scripts/dotfiles/deploy.sh"
                if declare -F deploy_symlinks &>/dev/null; then
                    deploy_symlinks
                fi
            fi
            ;;
    esac
}

# ── Verification ─────────────────────────────────────────────────────────

run_verification_summary() {
    echo
    echo -e "${BLUE_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${BOLD}Installation Summary${RESET}"
    echo -e "${BLUE_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo

    local tools="git gcc g++ python3 node rustc go docker nvim tmux zsh curl wget rg fzf btop ollama kubectl terraform ansible vagrant nmap wireshark socat iperf3 tailscale"
    local found=0
    local missing=0

    for tool in $tools; do
        if command -v "$tool" &>/dev/null; then
            found=$((found + 1))
            printf "  ${GREEN}✓${RESET} %-20s" "$tool"
        else
            missing=$((missing + 1))
            printf "  ${DIM}·${RESET} %-20s" "$tool"
        fi
    done
    echo
    echo
    echo -e "  ${BOLD}Result:${RESET} ${GREEN}${found} tools found${RESET}, ${YELLOW}${missing} not found${RESET}"
    echo
    echo -e "  ${DIM}Note: Some tools may need a shell restart or manual install${RESET}"
    echo
}

# ── Main ─────────────────────────────────────────────────────────────────

show_help() {
    echo "USMI Developer Workstation Bootstrap"
    echo
    echo "Interactive universal Linux installer. Run without arguments to"
    echo "launch the interactive menu and select components to install."
    echo
    echo "Usage: ./bootstrap-interactive.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo
    echo "Categories:"
    echo "  1  Development Essentials     git, gcc, cmake, python, node, neovim"
    echo "  2  AI Development             Ollama, PyTorch, transformers"
    echo "  3  Systems Programming        Rust, Go, Zig, Clang/LLVM"
    echo "  4  Web Development            Node, npm, pnpm, bun, yarn"
    echo "  5  DevOps & Cloud             Docker, K8s, Terraform, Ansible"
    echo "  6  Virtualization & Homelab   KVM, QEMU, Virt-Manager, Vagrant"
    echo "  7  Security & Networking      Tailscale, nmap, wireshark"
    echo "  8  Desktop Applications       Brave, VSCode, Obsidian"
    echo "  9  Shell & Dotfiles           Zsh, Starship, fonts, configs"
    echo "  a  Install Everything"
    echo
    echo "To use non-interactively (advanced):"
    echo "  source the core libs and call run_category for each number"
}

main() {
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi

    if [[ "$(id -u)" -eq 0 ]]; then
        echo -e "${RED}Do not run this script as root. It uses sudo when needed.${RESET}"
        exit 1
    fi

    if ! command -v sudo &>/dev/null; then
        echo -e "${RED}sudo is required but not installed.${RESET}"
        exit 1
    fi

    detect_environment
    detect_package_manager
    collect_stats

    mkdir -p "$(dirname "$LOG_FILE")"

    while true; do
        show_menu
        printf "  ${BOLD}Selection:${RESET} "
        read -r input

        [[ -z "$input" ]] && continue
        input="${input,,}"

        if [[ "$input" == "0" ]]; then
            echo
            echo -e "  ${YELLOW}Exiting.${RESET}"
            echo
            exit 0
        fi

        if [[ "$input" == "a" ]]; then
            SELECTED=(1 2 3 4 5 6 7 8 9)
        else
            local valid=true
            SELECTED=()
            for val in $input; do
                if [[ "$val" =~ ^[1-9]$ ]]; then
                    SELECTED+=("$val")
                else
                    valid=false
                fi
            done
            if ! $valid; then
                echo -e "  ${RED}Invalid selection. Please enter numbers 1-9 or 'a'.${RESET}"
                sleep 1
                continue
            fi
        fi

        if [[ ${#SELECTED[@]} -eq 0 ]]; then
            echo -e "  ${RED}No valid selections. Please try again.${RESET}"
            sleep 1
            continue
        fi

        clear
        show_banner
        echo -e "  ${BOLD}Selected Categories:${RESET}"
        for s in "${SELECTED[@]}"; do
            echo -e "    ${CYAN}•${RESET} $(get_category_name "$s")"
        done
        echo
        echo -e "  ${GREEN}Starting installation...${RESET}"
        sleep 1

        pkg_update

        for s in "${SELECTED[@]}"; do
            run_category "$s"
        done

        if declare -F run_verification &>/dev/null; then
            run_verification
        else
            run_verification_summary
        fi

        echo
        if command -v fastfetch &>/dev/null; then
            fastfetch
        elif command -v neofetch &>/dev/null; then
            neofetch
        fi

        echo -e "${GREEN_BOLD}"
        echo "  ╔══════════════════════════════════════╗"
        echo "  ║     Bootstrap Complete!              ║"
        echo "  ╚══════════════════════════════════════╝"
        echo -e "${RESET}"
        echo
        echo -e "  ${DIM}Log: ${LOG_FILE}${RESET}"
        echo
        if [[ "$SHELL" != *"zsh"* ]] && command -v zsh &>/dev/null; then
            echo -e "  ${YELLOW}Set Zsh as default:${RESET} chsh -s \"$(which zsh)\""
        fi
        echo -e "  ${YELLOW}Reload shell:${RESET}       exec \$SHELL"
        echo
        break
    done
}

main "$@"
