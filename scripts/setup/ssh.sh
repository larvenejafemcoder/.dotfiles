#!/usr/bin/env bash

setup_ssh_keys() {
    draw_section "SSH & GPG KEYS"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would generate SSH/GPG keys"
        return 0
    fi

    local ssh_dir="$HOME/.ssh"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    local email="${GIT_EMAIL:-commander@kernelghost.dev}"

    if [[ ! -f "$ssh_dir/id_ed25519" ]]; then
        log_info "Generating Ed25519 SSH key for GitHub..."
        ssh-keygen -t ed25519 -C "$email" -f "$ssh_dir/id_ed25519" -N "" &>/dev/null
        log_success "SSH key generated: id_ed25519"
        echo
        echo -e "  ${YELLOW}Public key:${RESET}"
        cat "$ssh_dir/id_ed25519.pub"
        echo
    else
        log_info "SSH key already exists: id_ed25519"
        echo -e "  ${YELLOW}Public key:${RESET}"
        cat "$ssh_dir/id_ed25519.pub"
        echo
    fi

    if [[ ! -f "$ssh_dir/id_rsa" ]]; then
        log_info "Generating legacy RSA key (for older systems)..."
        ssh-keygen -t rsa -b 4096 -C "$email" -f "$ssh_dir/id_rsa" -N "" &>/dev/null
        log_success "RSA key generated: id_rsa"
    fi

    eval "$(ssh-agent -s)" &>/dev/null
    ssh-add "$ssh_dir/id_ed25519" 2>/dev/null || true

    if command -v gpg &>/dev/null; then
        if ! gpg --list-secret-keys 2>/dev/null | grep -q "sec"; then
            log_info "Generating GPG key..."
            cat > /tmp/gpg-batch << EOF
%no-protection
%transient-key
Key-Type: eddsa
Key-Curve: ed25519
Name-Real: ${GIT_USERNAME:-Commander KernelGhost}
Name-Email: ${email}
Expire-Date: 0
EOF
            gpg --batch --generate-key /tmp/gpg-batch 2>/dev/null || {
                log_warn "GPG key generation failed (non-interactive mode)"
            }
            rm -f /tmp/gpg-batch
            log_success "GPG key generated"
        else
            log_info "GPG key already exists"
        fi

        echo
        echo -e "  ${YELLOW}GPG public key:${RESET}"
        gpg --armor --export "$email" 2>/dev/null || true
        echo
    fi

    if [[ ! -f "$HOME/.ssh/config" ]]; then
        cat > "$HOME/.ssh/config" << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host *
    AddKeysToAgent yes
    UseKeychain yes
    ServerAliveInterval 60
EOF
        chmod 600 "$HOME/.ssh/config"
        log_success "SSH config created"
    fi
}
