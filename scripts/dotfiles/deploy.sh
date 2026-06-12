#!/usr/bin/env bash

BACKUP_DIR=""

init_deploy() {
    BACKUP_DIR="${HOME}/.backup-$(date +%Y-%m-%d)"
    export BACKUP_DIR
    log_info "Backup directory: ${BACKUP_DIR}"
}

backup_existing_config() {
    local path="$1"
    local full_path="${HOME}/${path}"
    if [[ ! -e "$full_path" ]] || [[ -L "$full_path" ]]; then
        return 0
    fi
    mkdir -p "$BACKUP_DIR"
    local backup_path="${BACKUP_DIR}/${path//\//_}"
    cp -r "$full_path" "$backup_path" 2>/dev/null || true
    log_info "Backed up: ~/${path} → ${backup_path}"
}

deploy_with_stow() {
    local stow_dir="${DOTFILES_DIR}/stow"
    if [[ ! -d "$stow_dir" ]]; then
        log_error "Stow directory not found: ${stow_dir}"
        return 1
    fi
    if ! command -v stow &>/dev/null; then
        log_warn "GNU Stow not found, installing..."
        pkg_install stow
    fi
    if ! command -v stow &>/dev/null; then
        log_warn "GNU Stow still not available, falling back to manual deployment"
        deploy_manual
        return $?
    fi

    log_info "Deploying configs with GNU Stow..."
    local packages=()
    for pkg in "$stow_dir"/*/; do
        [[ -d "$pkg" ]] && packages+=("$(basename "$pkg")")
    done

    local success=0
    local failed=0
    (
        cd "$stow_dir" || return 1
        for pkg in "${packages[@]}"; do
            if [[ "${DRY_RUN:-false}" == "true" ]]; then
                log_info "[DRY-RUN] Would stow: ${pkg}"
                STATS_CONFIGS=$((STATS_CONFIGS + 1))
                continue
            fi
            if stow -R --no-folding -t "$HOME" "$pkg" 2>/dev/null; then
                log_success "Linked: ${pkg}"
                STATS_CONFIGS=$((STATS_CONFIGS + 1))
                success=$((success + 1))
            else
                log_warn "Failed to link: ${pkg}"
                failed=$((failed + 1))
                STATS_ERRORS=$((STATS_ERRORS + 1))
            fi
        done
    )
    log_info "Stow deployment: ${success} linked, ${failed} failed"
    return $failed
}

deploy_manual() {
    local stow_dir="${DOTFILES_DIR}/stow"
    log_info "Deploying configs manually..."

    local success=0
    local failed=0
    for package_dir in "$stow_dir"/*/; do
        [[ ! -d "$package_dir" ]] && continue
        local pkg_name
        pkg_name="$(basename "$package_dir")"
        log_info "Processing: ${pkg_name}"

        while IFS= read -r -d '' file; do
            local rel_path="${file#$package_dir}"
            local target="$HOME/$rel_path"

            if [[ "${DRY_RUN:-false}" == "true" ]]; then
                log_info "[DRY-RUN] Would link: ~/${rel_path}"
                STATS_CONFIGS=$((STATS_CONFIGS + 1))
                continue
            fi

            backup_existing_config "$rel_path"
            mkdir -p "$(dirname "$target")"
            ln -sf "$file" "$target"
            log_success "Linked: ~/${rel_path}"
            STATS_CONFIGS=$((STATS_CONFIGS + 1))
            success=$((success + 1))
        done < <(find "$package_dir" -type f -print0)
    done
    log_info "Manual deployment: ${success} linked, ${failed} failed"
}

deploy_symlinks() {
    init_deploy
    draw_section "DOTFILE DEPLOYMENT"
    mkdir -p "$HOME/.config"
    deploy_with_stow
    log_success "All config symlinks deployed"
}

verify_symlinks() {
    local stow_dir="${DOTFILES_DIR}/stow"
    local verified=0
    local missing=0

    for package_dir in "$stow_dir"/*/; do
        [[ ! -d "$package_dir" ]] && continue

        while IFS= read -r -d '' file; do
            local rel_path="${file#$package_dir}"
            local target="$HOME/$rel_path"

            if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$file" ]]; then
                verified=$((verified + 1))
            else
                log_warn "Missing or incorrect link: ~/${rel_path}"
                missing=$((missing + 1))
            fi
        done < <(find "$package_dir" -type f -print0)
    done

    log_info "Symlink verification: ${verified} correct, ${missing} missing"
    return $missing
}

rollback_symlinks() {
    log_info "Rolling back deployed symlinks..."
    local stow_dir="${DOTFILES_DIR}/stow"
    if command -v stow &>/dev/null; then
        (
            cd "$stow_dir" || return 1
            for pkg in */; do
                stow -D -t "$HOME" "$pkg" 2>/dev/null || true
            done
        )
    fi
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Restoring from backup: ${BACKUP_DIR}"
        for backup in "$BACKUP_DIR"/*; do
            [[ -f "$backup" ]] || continue
            local orig_name
            orig_name="$(basename "$backup")"
            local orig_path
            orig_path="$HOME/${orig_name//_//}"
            mkdir -p "$(dirname "$orig_path")"
            cp -r "$backup" "$orig_path" 2>/dev/null || true
            log_success "Restored: ${orig_path}"
        done
    fi
    log_success "Rollback completed"
}
