#!/usr/bin/env bash
# ── USMI Module: Docker & Container Setup ──

setup_docker() {
    draw_section "DOCKER SETUP"

    if ! is_installed docker; then
        log_warn "Docker not installed. Install via workload manifest first."
        return 1
    fi

    if ! groups "$USER" | grep -q docker; then
        log_info "Adding user to docker group..."
        sudo usermod -aG docker "$USER" 2>/dev/null || {
            log_error "Failed to add user to docker group"
            return 1
        }
        log_success "User added to docker group (log out/in to apply)"
    else
        log_info "User already in docker group"
    fi

    if command -v systemctl &>/dev/null; then
        log_info "Enabling Docker service..."
        sudo systemctl enable --now docker 2>/dev/null || {
            log_warn "Could not enable docker service"
            return 1
        }
        log_success "Docker service enabled"
    fi

    if is_installed docker-compose || docker compose version &>/dev/null 2>&1; then
        log_success "Docker Compose available"
    fi

    log_success "Docker ready"
}

setup_podman() {
    if ! is_installed podman; then
        log_warn "Podman not installed"
        return 1
    fi
    log_success "Podman available"
}

setup_portainer() {
    if docker ps 2>/dev/null | grep -q portainer; then
        log_success "Portainer already running"
        return 0
    fi

    log_info "Deploying Portainer..."
    docker volume create portainer_data 2>/dev/null
    docker run -d -p 8000:8000 -p 9443:9443 \
        --name portainer \
        --restart always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest 2>/dev/null || {
        log_warn "Portainer deploy failed"
        return 1
    }
    log_success "Portainer: https://localhost:9443"
}

docker_menu() {
    draw_section "CONTAINER SETUP"
    echo "  [1] Docker (+ compose, groups, service)"
    echo "  [2] Podman"
    echo "  [3] Portainer"
    echo "  [4] Everything"
    echo "  [0] Skip"
    echo
    read -rp "  Select: " dc_choice

    case "$dc_choice" in
        1) setup_docker ;;
        2) setup_podman ;;
        3) setup_portainer ;;
        4)
            setup_docker
            setup_podman
            setup_portainer
            ;;
        *) log_info "Container setup skipped" ;;
    esac
}
