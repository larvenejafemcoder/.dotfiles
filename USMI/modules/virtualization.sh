#!/usr/bin/env bash
# ── USMI Module: Virtualization & Homelab ──

setup_kvm() {
    draw_section "VIRTUALIZATION SETUP"

    if ! is_installed virsh; then
        log_warn "libvirt not installed. Install via workload manifest first."
        return 1
    fi

    if command -v systemctl &>/dev/null; then
        sudo systemctl enable --now libvirtd 2>/dev/null || log_warn "Could not enable libvirtd"
        sudo systemctl enable --now firewalld 2>/dev/null || true
    fi

    if ! groups "$USER" | grep -q libvirt; then
        log_info "Adding user to libvirt group..."
        sudo usermod -aG libvirt "$USER" 2>/dev/null || log_warn "Could not add to libvirt group"
    fi

    log_success "Virtualization stack ready"
}

setup_tailscale() {
    if is_installed tailscale; then
        log_success "Tailscale already installed"
        return 0
    fi

    log_info "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh 2>/dev/null || {
        log_warn "Tailscale install failed. See: https://tailscale.com/download"
        return 1
    }
    log_success "Tailscale installed"
    log_info "Run: sudo tailscale up"
}

homelab_menu() {
    draw_section "HOMELAB SETUP"
    echo "  [1] KVM / QEMU / Virt-Manager"
    echo "  [2] Tailscale"
    echo "  [3] Everything"
    echo "  [0] Skip"
    echo
    read -rp "  Select: " hl_choice

    case "$hl_choice" in
        1) setup_kvm ;;
        2) setup_tailscale ;;
        3)
            setup_kvm
            setup_tailscale
            ;;
        *) log_info "Homelab setup skipped" ;;
    esac
}
