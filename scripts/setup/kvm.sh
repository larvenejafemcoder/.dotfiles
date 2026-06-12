#!/usr/bin/env bash

setup_kvm() {
    draw_section "VIRTUALIZATION SETUP"
    log_info "Configuring KVM/QEMU optimized for Intel i3 + GTX 1650"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would configure KVM/QEMU"
        return 0
    fi

    if ! command -v virsh &>/dev/null; then
        log_info "Installing virtualization packages..."
        case "$DISTRO" in
            arch)
                pkg_install qemu-full
                pkg_install libvirt
                pkg_install virt-manager
                pkg_install edk2-ovmf
                pkg_install dnsmasq
                pkg_install bridge-utils
                pkg_install firewalld
                ;;
            ubuntu|debian)
                pkg_install qemu-system-x86
                pkg_install qemu-utils
                pkg_install libvirt-daemon-system
                pkg_install virt-manager
                pkg_install ovmf
                pkg_install dnsmasq
                pkg_install bridge-utils
                pkg_install firewalld
                ;;
            fedora|opensuse)
                pkg_install qemu-kvm
                pkg_install qemu-img
                pkg_install libvirt
                pkg_install virt-manager
                pkg_install edk2-ovmf
                pkg_install dnsmasq
                pkg_install bridge-utils
                pkg_install firewalld
                ;;
        esac
    else
        log_info "Virtualization packages already installed"
    fi

    if command -v systemctl &>/dev/null; then
        log_info "Enabling virtualization services..."

        sudo systemctl enable --now libvirtd 2>/dev/null && {
            log_success "libvirtd service enabled"
            STATS_SERVICES=$((STATS_SERVICES + 1))
        } || log_warn "Could not enable libvirtd"

        sudo systemctl enable --now firewalld 2>/dev/null || log_warn "Could not enable firewalld"
    fi

    if groups "$USER" | grep -q libvirt; then
        log_info "User already in libvirt group"
    else
        log_info "Adding user to libvirt group..."
        sudo usermod -aG libvirt "$USER" 2>/dev/null || log_warn "Could not add to libvirt group"
    fi

    if [[ -d /etc/libvirt ]]; then
        local qemu_conf="/etc/libvirt/qemu.conf"
        if [[ -f "$qemu_conf" ]]; then
            if ! grep -q "nvram" "$qemu_conf" 2>/dev/null; then
                log_info "Configuring UEFI/OVMF for VMs..."
                echo "nvram = [" | sudo tee -a "$qemu_conf" >/dev/null
                echo "  \"/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd\"" | sudo tee -a "$qemu_conf" >/dev/null
                echo "]" | sudo tee -a "$qemu_conf" >/dev/null
            fi
        fi
    fi

    log_success "KVM/QEMU optimized for Intel i3 + GTX 1650 + 20GB RAM"
}
