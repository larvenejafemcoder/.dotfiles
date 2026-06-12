#!/usr/bin/env bash

draw_header() {
    echo -e "${CYAN_BOLD}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║         RINNA DOTFILES DEPLOYMENT SYSTEM         ║"
    echo "║          Autonomous Workstation Setup           ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

draw_boot_screen() {
    clear
    draw_header
    echo
    echo -e "${CYAN_BOLD}  BOOTSTRAP INITIALIZATION${RESET}"
    echo
    local total=30
    for ((i = 1; i <= total; i++)); do
        local filled=$((i * 40 / total))
        printf "\r  ${GREEN}"
        for ((j = 0; j < filled; j++)); do printf "█"; done
        printf "${DIM}"
        for ((j = filled; j < 40; j++)); do printf "█"; done
        printf "${RESET} %3d%%" $((i * 100 / total))
        sleep 0.03
    done
    echo -e "\n\n${GREEN}  ✓ System initialized${RESET}"
    sleep 0.5
}

draw_progress_bar() {
    local percent=$1
    local width=${2:-30}
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    printf "\r  ${GREEN}"
    for ((i = 0; i < filled; i++)); do printf "█"; done
    printf "${DIM}"
    for ((i = 0; i < empty; i++)); do printf "░"; done
    printf "${RESET} %3d%%" "$percent"
}

draw_section() {
    local title="$1"
    echo
    echo -e "${BLUE_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN_BOLD}  ◆ $title${RESET}"
    echo -e "${BLUE_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

draw_table_row() {
    printf "  ${BOLD}%-20s${RESET} : ${CYAN}%s${RESET}\n" "$1" "$2"
}

draw_dashboard() {
    local -n status_ref=$1
    echo
    echo -e "${MAGENTA_BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${MAGENTA_BOLD}║${RESET}      ${BOLD}SYSTEM DEPLOYMENT STATUS${RESET}       ${MAGENTA_BOLD}║${RESET}"
    echo -e "${MAGENTA_BOLD}╠════════════════════════════════════════╣${RESET}"
    for key in "${!status_ref[@]}"; do
        local icon
        case "${status_ref[$key]}" in
            completed) icon="${GREEN}✓${RESET}" ;;
            skipped)   icon="${YELLOW}○${RESET}" ;;
            failed)    icon="${RED}✗${RESET}" ;;
            running)   icon="${CYAN}⟳${RESET}" ;;
            pending)   icon="${DIM}·${RESET}" ;;
            *)         icon="${DIM}·${RESET}" ;;
        esac
        printf "║  %-20s %-24b ║\n" "$key" "$icon"
    done
    echo -e "${MAGENTA_BOLD}╚════════════════════════════════════════╝${RESET}"
    echo
}

spinner_start() {
    local pid=$1
    local msg="${2:-Working}"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while ps -p "$pid" >/dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "\r  ${CYAN}%s${RESET} ${YELLOW}%s${RESET}" "${spinstr:0:1}" "$msg"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r${GREEN}  ✓${RESET} %s     \n" "$msg"
}

spinner_stop() {
    printf "\r${GREEN}  ✓${RESET} Done     \n"
}

confirm_action() {
    local prompt="$1"
    local default="${2:-n}"
    local yn
    if [[ "$UNATTENDED" == "true" ]]; then
        return 0
    fi
    read -rp "$prompt [y/N]: " yn
    case "$yn" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

print_separator() {
    echo -e "${DIM}────────────────────────────────────────────${RESET}"
}

final_banner() {
    echo
    echo -e "${GREEN_BOLD}"
    echo "██████╗ ██╗███╗   ██╗███╗   ██╗ █████╗ "
    echo "██╔══██╗██║████╗  ██║████╗  ██║██╔══██╗"
    echo "██████╔╝██║██╔██╗ ██║██╔██╗ ██║███████║"
    echo "██╔══██╗██║██║╚██╗██║██║╚██╗██║██╔══██║"
    echo "██║  ██║██║██║ ╚████║██║ ╚████║██║  ██║"
    echo "╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝  ╚═╝"
    echo -e "${RESET}"
    echo
    echo -e "${GREEN_BOLD}  DEPLOYMENT SUCCESSFUL${RESET}"
    echo -e "${CYAN_BOLD}  WORKSTATION READY${RESET}"
    echo -e "${YELLOW_BOLD}  WELCOME BACK COMMANDER${RESET}"
    echo
}
