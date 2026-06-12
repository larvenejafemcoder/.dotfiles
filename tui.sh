#!/usr/bin/env bash
# ── TUI Entry Point ─────────────────────────────────────────────────────
# Bootstraps Python virtual environment, installs Textual, and launches TUI.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${DOTFILES_DIR}/.tui-venv"

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}           ${BOLD}Dotfiles Setup Utility${NC}                   ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ! command -v python3 &>/dev/null; then
    echo -e "${CROSS} ${RED}Python 3 required but not installed.${NC}"
    exit 1
fi
echo -e "${CHECK} Python $(python3 --version 2>&1 | cut -d' ' -f2)"

if [ ! -d "$VENV_DIR" ]; then
    echo -e " ${BOLD}→${NC} Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi
echo -e "${CHECK} Virtual environment ready"

echo -e " ${BOLD}→${NC} Installing Textual..."
if ! "$VENV_DIR/bin/pip" install --quiet --upgrade textual 2>/dev/null; then
    echo -e "${CROSS} ${RED}Failed to install Textual.${NC}"
    exit 1
fi
echo -e "${CHECK} Textual ready"

chmod +x "$DOTFILES_DIR/scripts/grub.sh" 2>/dev/null || true

if [ -d "/boot/grub" ] || [ -d "/boot/grub2" ]; then
    echo -e "${CHECK} GRUB detected"
else
    echo -e "${YELLOW}⚠ GRUB not found${NC}"
fi

echo ""
echo -e " ${BOLD}→${NC} Launching..."
echo ""

exec "$VENV_DIR/bin/python" "$DOTFILES_DIR/main.py"
