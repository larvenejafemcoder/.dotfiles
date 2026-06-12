#!/usr/bin/env bash
# ── USMI Phase 4: Install Engine ──
# Reads manifests, resolves package names, installs

USMI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

resolve_package() {
    local pkg="$1"
    case "$DISTRO" in
        arch)
            case "$pkg" in
                python)        echo "python" ;;
                python-pip)    echo "python-pip" ;;
                python-venv)   echo "python-virtualenv" ;;
                fd)            echo "fd" ;;
                ninja)         echo "ninja" ;;
                docker)        echo "docker" ;;
                docker-compose) echo "docker-compose" ;;
                qemu)          echo "qemu-full" ;;
                libvirt)       echo "libvirt" ;;
                firewalld)     echo "firewalld" ;;
                golang)        echo "go" ;;
                build-essential) echo "base-devel" ;;
                *)             echo "$pkg" ;;
            esac
            ;;
        ubuntu|debian)
            case "$pkg" in
                python)        echo "python3" ;;
                python-pip)    echo "python3-pip" ;;
                python-venv)   echo "python3-venv" ;;
                fd)            echo "fd-find" ;;
                ninja)         echo "ninja-build" ;;
                docker)        echo "docker.io" ;;
                docker-compose) echo "docker-compose-v2" ;;
                qemu)          echo "qemu-system-x86" ;;
                libvirt)       echo "libvirt-daemon-system" ;;
                firewalld)     echo "firewalld" ;;
                golang)        echo "golang" ;;
                build-essential) echo "build-essential" ;;
                *)             echo "$pkg" ;;
            esac
            ;;
        fedora)
            case "$pkg" in
                python)        echo "python3" ;;
                python-pip)    echo "python3-pip" ;;
                python-venv)   echo "python3-virtualenv" ;;
                fd)            echo "fd-find" ;;
                ninja)         echo "ninja-build" ;;
                docker)        echo "docker" ;;
                docker-compose) echo "docker-compose" ;;
                qemu)          echo "qemu-kvm" ;;
                libvirt)       echo "libvirt" ;;
                firewalld)     echo "firewalld" ;;
                golang)        echo "golang" ;;
                build-essential) echo "@development-tools" ;;
                *)             echo "$pkg" ;;
            esac
            ;;
        opensuse)
            case "$pkg" in
                python)        echo "python3" ;;
                python-pip)    echo "python3-pip" ;;
                python-venv)   echo "python3-virtualenv" ;;
                fd)            echo "fd" ;;
                ninja)         echo "ninja" ;;
                docker)        echo "docker" ;;
                docker-compose) echo "docker-compose" ;;
                qemu)          echo "qemu-kvm" ;;
                libvirt)       echo "libvirt" ;;
                firewalld)     echo "firewalld" ;;
                golang)        echo "go" ;;
                build-essential) echo "patterns-devel-base-devel" ;;
                *)             echo "$pkg" ;;
            esac
            ;;
        *)
            echo "$pkg" ;;
    esac
}

install_special() {
    local pkg="$1"
    case "$pkg" in
        ollama)
            if is_installed ollama; then return 0; fi
            log_info "Installing Ollama via official script..."
            curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || return 1
            ;;
        rustup)
            if is_installed rustup || is_installed rustc; then return 0; fi
            log_info "Installing Rust via rustup..."
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>/dev/null || return 1
            ;;
        lazygit)
            if is_installed lazygit; then return 0; fi
            log_info "Installing Lazygit via go..."
            if is_installed go; then
                go install github.com/jesseduffield/lazygit@latest 2>/dev/null || return 1
            else
                log_warn "Go required for lazygit install. Install go first."
                return 1
            fi
            ;;
        godot)
            if is_installed godot || is_installed godot4; then return 0; fi
            log_info "Install Godot manually from: https://godotengine.org/download"
            return 1
            ;;
        podman)
            if is_installed podman; then return 0; fi
            log_info "Installing Podman..."
            case "$DISTRO" in
                arch)   sudo pacman -S --needed --noconfirm podman podman-docker ;;
                ubuntu|debian) sudo apt install -y podman podman-docker ;;
                fedora) sudo dnf install -y podman podman-docker ;;
                opensuse) sudo zypper install -y podman podman-docker ;;
            esac 2>/dev/null || return 1
            ;;
        kubectl)
            if is_installed kubectl; then return 0; fi
            log_info "Installing kubectl..."
            case "$DISTRO" in
                arch)   sudo pacman -S --needed --noconfirm kubectl ;;
                ubuntu|debian)
                    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null
                    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
                    sudo apt update && sudo apt install -y kubectl 2>/dev/null || return 1
                    ;;
                fedora)
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 2>/dev/null
                    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl 2>/dev/null || return 1
                    ;;
                opensuse) sudo zypper install -y kubectl 2>/dev/null || return 1 ;;
            esac
            ;;
        helm)
            if is_installed helm; then return 0; fi
            log_info "Installing Helm..."
            curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 2>/dev/null || return 1
            ;;
        minikube)
            if is_installed minikube; then return 0; fi
            log_info "Installing Minikube..."
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 2>/dev/null
            sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64 2>/dev/null || return 1
            ;;
        terraform)
            if is_installed terraform; then return 0; fi
            log_info "Installing Terraform..."
            case "$DISTRO" in
                arch)   sudo pacman -S --needed --noconfirm terraform ;;
                ubuntu|debian)
                    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
                    echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
                    sudo apt update && sudo apt install -y terraform 2>/dev/null || return 1
                    ;;
                fedora) sudo dnf install -y terraform 2>/dev/null || return 1 ;;
                opensuse) sudo zypper install -y terraform 2>/dev/null || return 1 ;;
            esac
            ;;
        ansible)
            if is_installed ansible; then return 0; fi
            log_info "Installing Ansible..."
            case "$DISTRO" in
                arch)   sudo pacman -S --needed --noconfirm ansible ;;
                ubuntu|debian)
                    sudo apt install -y ansible 2>/dev/null || {
                        python3 -m pip install --user ansible 2>/dev/null || return 1
                    }
                    ;;
                fedora) sudo dnf install -y ansible 2>/dev/null || return 1 ;;
                opensuse) sudo zypper install -y ansible 2>/dev/null || return 1 ;;
            esac
            ;;
        vagrant)
            if is_installed vagrant; then return 0; fi
            log_info "Installing Vagrant..."
            case "$DISTRO" in
                arch)   sudo pacman -S --needed --noconfirm vagrant ;;
                ubuntu|debian)
                    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
                    echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
                    sudo apt update && sudo apt install -y vagrant 2>/dev/null || return 1
                    ;;
                fedora) sudo dnf install -y vagrant 2>/dev/null || return 1 ;;
                opensuse) sudo zypper install -y vagrant 2>/dev/null || return 1 ;;
            esac
            ;;
        *)
            return 2 ;;
    esac
    log_success "Installed: $pkg"
    return 0
}

pkg_install() {
    local pkg="$1"

    # Try special install first
    install_special "$pkg" && return 0

    local resolved
    resolved=$(resolve_package "$pkg")

    if is_package_installed "$resolved" 2>/dev/null; then
        log_debug "Already installed: $resolved"
        return 0
    fi

    log_info "Installing: $resolved"

    case "$DISTRO" in
        arch)   sudo pacman -S --needed --noconfirm "$resolved" 2>/dev/null ;;
        ubuntu|debian) sudo apt install -y "$resolved" 2>/dev/null ;;
        fedora) sudo dnf install -y "$resolved" 2>/dev/null ;;
        opensuse) sudo zypper install -y "$resolved" 2>/dev/null ;;
    esac || {
        log_warn "Failed to install: $resolved"
        return 1
    }

    log_success "Installed: $resolved"
}

pkg_install_list() {
    local -a packages=("$@")
    local total=${#packages[@]}
    local count=0

    for pkg in "${packages[@]}"; do
        pkg_install "$pkg"
    done
}

pkg_update() {
    log_info "Updating package database..."
    case "$DISTRO" in
        arch)   sudo pacman -Sy --noconfirm ;;
        ubuntu|debian) sudo apt update ;;
        fedora) sudo dnf check-update || true ;;
        opensuse) sudo zypper refresh ;;
    esac
    log_success "Package database updated"
}

install_profile() {
    local profile="$1"
    local manifest="$USMI_DIR/manifests/${profile}.conf"

    if [[ ! -f "$manifest" ]]; then
        log_error "Manifest not found: ${profile}.conf"
        return 1
    fi

    log_info "Loading profile: ${profile}"

    local packages=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line// /}"
        [[ -z "$line" ]] && continue
        packages+=("$line")
    done < "$manifest"

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No packages in manifest: ${profile}"
        return 0
    fi

    pkg_install_list "${packages[@]}"
}

install_aur() {
    local pkg="$1"
    if command -v "${AUR_HELPER:-yay}" &>/dev/null; then
        log_info "Installing AUR: $pkg"
        ${AUR_HELPER:-yay} -S --needed --noconfirm "$pkg" 2>/dev/null || log_warn "AUR install failed: $pkg"
    else
        log_info "Installing yay AUR helper..."
        local tmpdir
        tmpdir="$(mktemp -d)"
        git clone --depth=1 https://aur.archlinux.org/yay.git "$tmpdir/yay" 2>/dev/null
        (cd "$tmpdir/yay" && makepkg -si --noconfirm) 2>/dev/null || true
        rm -rf "$tmpdir"
        AUR_HELPER="yay"
        if command -v yay &>/dev/null; then
            yay -S --needed --noconfirm "$pkg" 2>/dev/null || log_warn "AUR install failed: $pkg"
        fi
    fi
}
