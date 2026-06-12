#!/usr/bin/env bash
# ── USMI Phase 6: AI Workstation Module ──
# Ollama, Open WebUI, CUDA, Jupyter

install_ollama() {
    if is_installed ollama; then
        log_success "Ollama already installed"
        return 0
    fi
    log_info "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || {
        log_error "Ollama install failed"
        return 1
    }
    log_success "Ollama installed"
    log_info "Pull models: ollama pull qwen3"
}

install_open_webui() {
    if docker ps 2>/dev/null | grep -q open-webui; then
        log_success "Open WebUI already running"
        return 0
    fi
    log_info "Deploying Open WebUI via Docker..."
    docker run -d -p 3000:8080 \
        --add-host=host.docker.internal:host-gateway \
        -v open-webui:/app/backend/data \
        --name open-webui \
        --restart always \
        ghcr.io/open-webui/open-webui:main 2>/dev/null || {
        log_warn "Open WebUI deploy failed"
        return 1
    }
    log_success "Open WebUI running at http://localhost:3000"
}

install_cuda() {
    if is_installed nvidia-smi; then
        log_success "NVIDIA drivers detected"
    else
        log_warn "NVIDIA drivers not found. Install manually."
    fi

    case "$DISTRO" in
        arch)
            log_info "Installing CUDA via pacman..."
            sudo pacman -S --needed --noconfirm cuda cuda-tools 2>/dev/null || {
                log_warn "CUDA not in default repos. Install from AUR: cuda"
                return 1
            }
            ;;
        ubuntu|debian)
            log_info "Installing CUDA via NVIDIA repo..."
            wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb 2>/dev/null
            sudo dpkg -i cuda-keyring_1.1-1_all.deb 2>/dev/null
            sudo apt update 2>/dev/null
            sudo apt install -y cuda-toolkit 2>/dev/null || {
                log_warn "CUDA install failed. See: https://developer.nvidia.com/cuda-downloads"
                return 1
            }
            rm -f cuda-keyring_1.1-1_all.deb
            ;;
        fedora)
            sudo dnf install -y cuda-toolkit 2>/dev/null || {
                log_warn "CUDA install failed. See: https://developer.nvidia.com/cuda-downloads"
                return 1
            }
            ;;
        opensuse)
            sudo zypper install -y cuda-toolkit 2>/dev/null || {
                log_warn "CUDA install failed. See: https://developer.nvidia.com/cuda-downloads"
                return 1
            }
            ;;
    esac
    log_success "CUDA toolkit installed"
}

install_jupyter() {
    if is_installed jupyter-lab || is_installed jupyter; then
        log_success "Jupyter already installed"
        return 0
    fi
    log_info "Installing Jupyter Lab..."
    if is_installed pip3; then
        pip3 install --user jupyterlab notebook 2>/dev/null || {
            pip3 install --user --break-system-packages jupyterlab notebook 2>/dev/null || {
                log_error "Jupyter install failed"
                return 1
            }
        }
        log_success "Jupyter Lab installed"
        log_info "Run: jupyter lab"
    else
        log_error "pip3 required for Jupyter"
        return 1
    fi
}

ai_menu() {
    draw_section "AI COMPONENTS"
    echo "  [1] Ollama"
    echo "  [2] Open WebUI (Docker)"
    echo "  [3] CUDA Toolkit"
    echo "  [4] Jupyter Lab"
    echo "  [5] Everything"
    echo "  [0] Skip"
    echo
    read -rp "  Select AI components: " ai_choice

    case "$ai_choice" in
        1) install_ollama ;;
        2) install_open_webui ;;
        3) install_cuda ;;
        4) install_jupyter ;;
        5)
            install_ollama
            install_open_webui
            install_cuda
            install_jupyter
            ;;
        *) log_info "AI components skipped" ;;
    esac
}
