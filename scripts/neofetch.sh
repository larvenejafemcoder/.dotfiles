#!/usr/bin/env bash
# ── Neofetch Theme Manager ──────────────────────────────────────────────
# Manages neofetch themes from the Chick2D/neofetch-themes collection.
# https://github.com/Chick2D/neofetch-themes

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEMES_DIR="${DOTFILES_DIR}/neofetch-themes"
NEOFETCH_CONFIG="${HOME}/.config/neofetch/config.conf"
NEOFETCH_BACKUP="${HOME}/.config/neofetch/config.conf.bak"

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ── Theme discovery ────────────────────────────────────────────────────────

discover_themes() {
    local themes=()
    local category="$1"  # "normal" or "small" or "all"

    if [[ ! -d "$THEMES_DIR" ]]; then
        echo ""
        return
    fi

    if [[ "$category" == "normal" || "$category" == "all" ]]; then
        for entry in "$THEMES_DIR/normal/"*; do
            local name
            if [[ -f "$entry" && "$entry" == *.conf ]]; then
                name=$(basename "${entry%.conf}")
                echo "normal|$name|$entry"
            elif [[ -d "$entry" && -f "$entry/config.conf" ]]; then
                name=$(basename "$entry")
                echo "normal|$name|$entry/config.conf"
            fi
        done
    fi

    if [[ "$category" == "small" || "$category" == "all" ]]; then
        for entry in "$THEMES_DIR/small/"*; do
            local name
            if [[ -f "$entry" && "$entry" == *.conf ]]; then
                name=$(basename "${entry%.conf}")
                echo "small|$name|$entry"
            elif [[ -d "$entry" && -f "$entry/config.conf" ]]; then
                name=$(basename "$entry")
                echo "small|$name|$entry/config.conf"
            fi
        done
    fi
}

# ── Status ─────────────────────────────────────────────────────────────────

get_current_theme() {
    if [[ ! -f "$NEOFETCH_CONFIG" ]]; then
        echo "none"
        return
    fi

    local md5_current
    local md5_theme
    md5_current=$(md5sum "$NEOFETCH_CONFIG" 2>/dev/null | cut -d' ' -f1)

    discover_themes "all" | while IFS='|' read -r cat name path; do
        md5_theme=$(md5sum "$path" 2>/dev/null | cut -d' ' -f1)
        if [[ "$md5_current" == "$md5_theme" ]]; then
            echo "$name"
            return
        fi
    done

    if grep -q "^# Neofetch Theme:" "$NEOFETCH_CONFIG" 2>/dev/null; then
        grep "^# Neofetch Theme:" "$NEOFETCH_CONFIG" | head -1 | sed 's/^# Neofetch Theme: //'
        return
    fi

    echo "custom"
}

get_themes_count() {
    discover_themes "all" | wc -l
}

# ── Apply theme ────────────────────────────────────────────────────────────

apply_theme() {
    local query="$1"
    local theme_path=""
    local theme_name=""

    while IFS='|' read -r cat name path; do
        if [[ "${name,,}" == "${query,,}" ]]; then
            theme_path="$path"
            theme_name="$name"
            break
        fi
    done < <(discover_themes "all")

    if [[ -z "$theme_path" ]]; then
        # Try partial match
        while IFS='|' read -r cat name path; do
            if [[ "${name,,}" == *"${query,,}"* ]]; then
                theme_path="$path"
                theme_name="$name"
                break
            fi
        done < <(discover_themes "all")
    fi

    if [[ -z "$theme_path" ]]; then
        echo -e "${RED}Theme '$query' not found${NC}"
        echo "Use --list to see available themes"
        exit 1
    fi

    mkdir -p "$(dirname "$NEOFETCH_CONFIG")"

    if [[ -f "$NEOFETCH_CONFIG" ]]; then
        cp "$NEOFETCH_CONFIG" "$NEOFETCH_BACKUP"
    fi

    cp "$theme_path" "$NEOFETCH_CONFIG"

    echo -e "${GREEN}✓ Applied theme:${NC} $theme_name ($cat)"

    if grep -q "^# Neofetch Theme:" "$theme_path" 2>/dev/null; then
        :
    else
        sed -i "1i# Neofetch Theme: $theme_name\n" "$NEOFETCH_CONFIG" 2>/dev/null || true
    fi
}

# ── List themes ────────────────────────────────────────────────────────────

list_themes() {
    local current
    current=$(get_current_theme)

    echo -e "${BOLD}Available Neofetch Themes${NC}\n"

    local count=0
    local idx=1
    local cat_prev=""

    while IFS='|' read -r cat name path; do
        if [[ "$cat" != "$cat_prev" ]]; then
            [[ -n "$cat_prev" ]] && echo ""
            echo -e "${CYAN}▶ ${cat^}${NC}"
            cat_prev="$cat"
        fi

        marker=" "
        [[ "$name" == "$current" ]] && marker="${GREEN}●${NC}"

        printf "  ${CYAN}%2d${NC}) %s %-25s\n" "$idx" "$marker" "$name"
        idx=$((idx + 1))
        count=$((count + 1))
    done < <(discover_themes "all")

    echo ""
    echo -e "${BOLD}Total:${NC} $count themes"
    echo -e "${GREEN}●${NC} = currently applied"
    echo ""
    echo "Usage: $(basename "$0") --apply \"Theme Name\""
}

# ── Backup / Restore ───────────────────────────────────────────────────────

backup_config() {
    if [[ ! -f "$NEOFETCH_CONFIG" ]]; then
        echo -e "${YELLOW}No config to backup${NC}"
        return
    fi
    cp "$NEOFETCH_CONFIG" "$NEOFETCH_BACKUP"
    echo -e "${GREEN}✓ Backed up to${NC} $NEOFETCH_BACKUP"
}

restore_config() {
    if [[ ! -f "$NEOFETCH_BACKUP" ]]; then
        echo -e "${YELLOW}No backup found at${NC} $NEOFETCH_BACKUP"
        exit 1
    fi
    cp "$NEOFETCH_BACKUP" "$NEOFETCH_CONFIG"
    echo -e "${GREEN}✓ Restored from backup${NC}"
}

# ── Update themes ──────────────────────────────────────────────────────────

update_themes() {
    echo -e "Updating theme list..."

    if [[ -d "$THEMES_DIR/.git" ]]; then
        git -C "$THEMES_DIR" pull --ff-only 2>/dev/null && \
            echo -e "${GREEN}✓ Themes updated${NC}" || \
            echo -e "${YELLOW}Already up to date${NC}"
    else
        echo -e "Cloning neofetch-themes..."
        rm -rf "$THEMES_DIR"
        git clone --depth 1 https://github.com/Chick2D/neofetch-themes.git "$THEMES_DIR" 2>/dev/null && \
            echo -e "${GREEN}✓ Themes cloned${NC}" || \
            echo -e "${RED}Failed to clone${NC}"
    fi
}

# ── CLI ────────────────────────────────────────────────────────────────────

case "${1:-}" in
    --list|-l)
        list_themes
        ;;
    --current|-c)
        get_current_theme
        ;;
    --apply|-a)
        [[ -z "${2:-}" ]] && { echo "Specify theme name"; exit 1; }
        apply_theme "$2"
        ;;
    --backup|-b)
        backup_config
        ;;
    --restore|-r)
        restore_config
        ;;
    --update|-u)
        update_themes
        ;;
    --help|-h|*)
        echo -e "${BOLD}Neofetch Theme Manager${NC}"
        echo ""
        echo "Usage:"
        echo "  $(basename "$0") --list              List available themes"
        echo "  $(basename "$0") --current           Show current theme"
        echo "  $(basename "$0") --apply \"Name\"      Apply a theme"
        echo "  $(basename "$0") --backup            Backup current config"
        echo "  $(basename "$0") --restore           Restore from backup"
        echo "  $(basename "$0") --update            Update theme collection"
        echo "  $(basename "$0") --help              This help"
        ;;
esac
