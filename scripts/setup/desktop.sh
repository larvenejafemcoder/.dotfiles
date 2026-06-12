#!/usr/bin/env bash

DESKTOP_PROFILE="${DESKTOP_PROFILE:-default}"

setup_hyprland() {
    draw_section "HYPRLAND SETUP"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install Hyprland"
        return 0
    fi

    log_info "Installing Hyprland packages..."

    case "$DISTRO" in
        arch)
            pkg_install hyprland
            pkg_install xdg-desktop-portal-hyprland
            pkg_install dunst
            pkg_install rofi
            pkg_install waybar
            pkg_install swappy
            pkg_install grim
            pkg_install slurp
            pkg_install wl-clipboard
            pkg_install brightnessctl
            pkg_install pavucontrol
            pkg_install pipewire
            pkg_install pipewire-pulse
            pkg_install wireplumber
            pkg_install polkit-gnome
            ;;
        ubuntu|debian)
            if ! command -v hyprland &>/dev/null; then
                log_warn "Hyprland may not be in official repos. Installing from source/PPA."
            fi
            pkg_install xdg-desktop-portal-hyprland || true
            pkg_install dunst || true
            pkg_install rofi || true
            pkg_install waybar || true
            pkg_install grim || true
            pkg_install slurp || true
            pkg_install wl-clipboard || true
            pkg_install brightnessctl || true
            pkg_install pavucontrol
            pkg_install pipewire
            pkg_install pipewire-pulse
            pkg_install wireplumber
            ;;
        fedora|opensuse)
            pkg_install hyprland || true
            pkg_install xdg-desktop-portal-hyprland || true
            pkg_install dunst || true
            pkg_install rofi || true
            pkg_install waybar || true
            pkg_install grim || true
            pkg_install slurp || true
            pkg_install wl-clipboard || true
            pkg_install brightnessctl || true
            pkg_install pavucontrol
            pkg_install pipewire
            pkg_install pipewire-pulse
            pkg_install wireplumber
            ;;
    esac

    if command -v systemctl --user &>/dev/null; then
        systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    fi

    log_success "Hyprland environment prepared"
}

setup_i3() {
    draw_section "I3 SETUP"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would install i3"
        return 0
    fi

    log_info "Installing i3 packages..."

    case "$DISTRO" in
        arch)
            pkg_install i3-wm
            pkg_install i3status
            pkg_install i3lock
            pkg_install dmenu
            pkg_install picom
            pkg_install polybar
            pkg_install feh
            pkg_install nitrogen
            pkg_install dunst
            pkg_install rofi
            pkg_install xclip
            pkg_install xorg-xrandr
            pkg_install xorg-xbacklight
            pkg_install pulseaudio
            pkg_install pavucontrol
            ;;
        ubuntu|debian)
            pkg_install i3
            pkg_install i3status
            pkg_install i3lock
            pkg_install suckless-tools
            pkg_install picom
            pkg_install polybar || true
            pkg_install feh
            pkg_install nitrogen || true
            pkg_install dunst
            pkg_install rofi
            pkg_install xclip
            pkg_install x11-xserver-utils
            pkg_install pulseaudio
            pkg_install pavucontrol
            ;;
        fedora|opensuse)
            pkg_install i3
            pkg_install i3status
            pkg_install i3lock
            pkg_install dmenu
            pkg_install picom
            pkg_install polybar || true
            pkg_install feh
            pkg_install nitrogen || true
            pkg_install dunst
            pkg_install rofi
            pkg_install xclip
            pkg_install xrandr
            pkg_install pulseaudio
            pkg_install pavucontrol
            ;;
    esac

    log_success "i3 environment prepared"
}

setup_desktop() {
    if [[ "$DESKTOP_PROFILE" == "hyprland" ]]; then
        setup_hyprland
    elif [[ "$DESKTOP_PROFILE" == "i3" ]]; then
        setup_i3
    elif [[ "$DESKTOP_PROFILE" == "default" ]]; then
        # Auto-detect based on existing environment
        if [[ "$DESKTOP" == *"Hyprland"* ]]; then
            setup_hyprland
        elif [[ "$DESKTOP" == *"i3"* ]]; then
            setup_i3
        else
            log_info "No specific desktop profile selected (use --profile hyprland or --profile i3)"
            log_info "Installing common desktop tools..."
            pkg_install pipewire 2>/dev/null || true
            pkg_install pavucontrol 2>/dev/null || true
        fi
    fi
}
