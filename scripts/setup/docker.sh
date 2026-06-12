#!/usr/bin/env bash

setup_docker() {
    draw_section "DOCKER SETUP"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would set up Docker"
        return 0
    fi

    if command -v docker &>/dev/null; then
        log_info "Docker already installed"
    else
        log_info "Installing Docker..."
        case "$DISTRO" in
            arch)
                pkg_install docker
                pkg_install docker-compose
                ;;
            ubuntu|debian)
                pkg_install docker.io
                pkg_install docker-compose-v2
                ;;
            fedora|opensuse)
                pkg_install docker
                pkg_install docker-compose
                ;;
        esac
    fi

    if command -v docker &>/dev/null; then
        log_success "Docker installed: $(docker --version 2>/dev/null || true)"

        if ! groups "$USER" | grep -q docker; then
            log_info "Adding user to docker group..."
            sudo usermod -aG docker "$USER" 2>/dev/null || log_warn "Could not add user to docker group"
        fi

        log_info "Enabling and starting Docker service..."
        if command -v systemctl &>/dev/null; then
            sudo systemctl enable --now docker 2>/dev/null || log_warn "Could not enable docker service"
        fi

        if command -v docker-compose &>/dev/null || docker compose version &>/dev/null; then
            log_success "Docker Compose available"
        fi

        STATS_SERVICES=$((STATS_SERVICES + 1))
    else
        log_error "Docker installation failed"
    fi
}
