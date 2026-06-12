#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                      🎨 Gorgeous GRUB Installer                          ║
# ║        Interactive GRUB theme installer from Gorgeous-GRUB collection    ║
# ║                    https://github.com/Jacksaur/Gorgeous-GRUB             ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
GRUB_THEMES_DIR="/boot/grub/themes"
GRUB_CONFIG="/etc/default/grub"
TEMP_DIR="/tmp/gorgeous-grub-install"
CONFIG_DIR="$HOME/.config/gorgeous-grub"
CONFIG_FILE="$CONFIG_DIR/config"
THEMES_DB="$CONFIG_DIR/themes.db"
USE_GUM=false
LANG_CODE="en"

# Check for gum
if command -v gum &> /dev/null; then
    USE_GUM=true
fi

# ════════════════════════════════════════════════════════════════════════════
# 🌍 LOCALIZATION
# ════════════════════════════════════════════════════════════════════════════

declare -A L

load_english() {
    L[title]="Gorgeous GRUB Installer"
    L[subtitle]="Beautiful themes for your bootloader"
    L[current_theme]="Current theme"
    L[installed_themes]="Installed themes"
    L[install_new]="Install new theme"
    L[rescan_themes]="Rescan theme list"
    L[apply_installed]="Apply installed theme"
    L[remove_theme]="Remove theme"
    L[reboot]="Reboot system"
    L[set_resolution]="Set resolution"
    L[disable_double]="Disable Minegrub double menu"
    L[reset_default]="Reset to default settings"
    L[exit]="Exit"
    L[goodbye]="Goodbye!"
    L[select_theme]="Select theme to install"
    L[use_arrows]="Use ↑↓ to navigate, Enter to select, Esc to cancel"
    L[search_placeholder]="Search theme..."
    L[cloning]="Cloning repository..."
    L[found_theme]="Found theme"
    L[copying]="Copying to"
    L[applying]="Applying theme..."
    L[updating_grub]="Updating GRUB config..."
    L[success]="Theme applied successfully!"
    L[reboot_msg]="Reboot to see changes."
    L[press_enter]="Press Enter to continue..."
    L[theme_not_found]="theme.txt not found"
    L[clone_failed]="Failed to clone repository"
    L[folder_not_found]="Folder not found"
    L[pling_manual]="Pling themes require manual download."
    L[pling_instructions]="To install theme"
    L[open_url]="Open URL"
    L[download_archive]="Download archive from Files tab"
    L[extract_to]="Extract to"
    L[run_again]="Run script again and apply theme"
    L[open_browser]="Open link in browser?"
    L[select_installed]="Select installed theme to apply"
    L[no_themes]="No installed themes found"
    L[select_remove]="Select theme to remove"
    L[confirm_remove]="Remove theme"
    L[removed]="Theme removed"
    L[cancelled]="Cancelled"
    L[resolution_title]="GRUB Resolution Settings"
    L[current_resolution]="Current resolution"
    L[enter_manually]="Enter manually..."
    L[resolution_set]="Resolution set"
    L[double_disabled]="Double menu disabled"
    L[grub_lang]="GRUB language"
    L[grub_lang_set]="GRUB language set to"
    L[grub_lang_note]="Note: Some themes don't support Cyrillic fonts"
    L[select_language]="Select language"
    L[language_saved]="Language saved"
    L[settings]="Settings"
    L[change_language]="Change language"
    L[dependencies_missing]="Missing dependencies"
    L[grub_not_found]="GRUB not found!"
    L[using_grub]="Using"
    L[install_script]="Running install script..."
    L[install_complete]="Installation complete!"
    L[fix_fonts]="Fix theme fonts (Cyrillic)"
    L[select_font]="Select system font"
    L[font_replaced]="Font replaced successfully"
    L[no_theme_applied]="No theme applied"
    L[updating_list]="Updating theme list..."
    L[list_updated]="Theme list updated!"
    L[update_failed]="Failed to update theme list"

    # Categories
    L[cat_gaming]="Gaming"
    L[cat_cyberpunk]="Cyberpunk"
    L[cat_anime]="Anime"
    L[cat_minimal]="Minimal"
    L[cat_scifi]="Sci-Fi"
    L[cat_other]="Other"
}

load_russian() {
    L[title]="Gorgeous GRUB Installer"
    L[subtitle]="Красивые темы для вашего загрузчика"
    L[current_theme]="Текущая тема"
    L[installed_themes]="Установлено тем"
    L[install_new]="Установить новую тему"
    L[rescan_themes]="Обновить список тем"
    L[apply_installed]="Применить установленную тему"
    L[remove_theme]="Удалить тему"
    L[reboot]="Перезагрузить систему"
    L[set_resolution]="Настроить разрешение"
    L[disable_double]="Отключить двойное меню Minegrub"
    L[reset_default]="Сбросить настройки по умолчанию"
    L[exit]="Выход"
    L[goodbye]="До свидания!"
    L[select_theme]="Выберите тему для установки"
    L[use_arrows]="Используйте ↑↓ для навигации, Enter для выбора, Esc для отмены"
    L[search_placeholder]="Поиск темы..."
    L[cloning]="Клонирование репозитория..."
    L[found_theme]="Найдена тема"
    L[copying]="Копирование в"
    L[applying]="Применение темы..."
    L[updating_grub]="Обновление конфигурации GRUB..."
    L[success]="Тема успешно применена!"
    L[reboot_msg]="Перезагрузите компьютер, чтобы увидеть изменения."
    L[press_enter]="Нажмите Enter для продолжения..."
    L[theme_not_found]="theme.txt не найден"
    L[clone_failed]="Не удалось клонировать репозиторий"
    L[folder_not_found]="Папка не найдена"
    L[pling_manual]="Темы с Pling требуют ручной загрузки."
    L[pling_instructions]="Для установки темы"
    L[open_url]="Откройте"
    L[download_archive]="Скачайте архив из вкладки Files"
    L[extract_to]="Распакуйте в"
    L[run_again]="Запустите скрипт снова и примените тему"
    L[open_browser]="Открыть ссылку в браузере?"
    L[select_installed]="Выберите тему для применения"
    L[no_themes]="Установленные темы не найдены"
    L[select_remove]="Выберите тему для удаления"
    L[confirm_remove]="Удалить тему"
    L[removed]="Тема удалена"
    L[cancelled]="Отменено"
    L[resolution_title]="Настройка разрешения GRUB"
    L[current_resolution]="Текущее разрешение"
    L[enter_manually]="Ввести вручную..."
    L[resolution_set]="Resolution set"
    L[reset_complete]="Settings reset to default"
    L[double_disabled]="Double menu disabled"
    L[grub_lang]="Язык GRUB"
    L[grub_lang_set]="Язык GRUB изменён на"
    L[grub_lang_note]="Примечание: Некоторые темы не поддерживают кириллицу"
    L[select_language]="Выберите язык"
    L[language_saved]="Язык сохранён"
    L[settings]="Настройки"
    L[change_language]="Сменить язык"
    L[dependencies_missing]="Отсутствуют зависимости"
    L[grub_not_found]="GRUB не найден!"
    L[using_grub]="Используется"
    L[install_script]="Запуск скрипта установки..."
    L[install_complete]="Установка завершена!"
    L[fix_fonts]="Исправить шрифты темы (кириллица)"
    L[select_font]="Выберите системный шрифт"
    L[font_replaced]="Шрифт успешно заменён"
    L[no_theme_applied]="Тема не применена"
    L[updating_list]="Обновление списка тем..."
    L[list_updated]="Список тем обновлен!"
    L[update_failed]="Не удалось обновить список"

    # Categories
    L[cat_gaming]="Игровые"
    L[cat_cyberpunk]="Киберпанк"
    L[cat_anime]="Аниме"
    L[cat_minimal]="Минимализм"
    L[cat_scifi]="Sci-Fi"
    L[cat_other]="Другие"
}

load_language() {
    case "$LANG_CODE" in
        ru) load_russian ;;
        *) load_english ;;
    esac
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    echo "LANG_CODE=$LANG_CODE" > "$CONFIG_FILE"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

select_language() {
    if $USE_GUM; then
        local selected
        selected=$(printf "English\nРусский" | gum choose --cursor "▸ " --cursor.foreground 212)
        case "$selected" in
            "Русский") LANG_CODE="ru" ;;
            *) LANG_CODE="en" ;;
        esac
    else
        echo ""
        echo "Select language / Выберите язык:"
        echo "  1) English"
        echo "  2) Русский"
        read -p "> " choice
        case "$choice" in
            2) LANG_CODE="ru" ;;
            *) LANG_CODE="en" ;;
        esac
    fi
    save_config
    load_language
    print_success "${L[language_saved]}"
    sleep 1
}

# Theme database with translations
get_category_name() {
    local cat=$1
    case "$cat" in
        "gaming") echo "${L[cat_gaming]}" ;;
        "cyberpunk") echo "${L[cat_cyberpunk]}" ;;
        "anime") echo "${L[cat_anime]}" ;;
        "minimal") echo "${L[cat_minimal]}" ;;
        "scifi") echo "${L[cat_scifi]}" ;;
        *) echo "${L[cat_other]}" ;;
    esac
}

# Theme database: "Name|URL|Type|Folder|Desc_EN|Desc_RU|Category"
declare -a THEMES=()
declare -a DEFAULT_THEMES=(
    "Minegrub|https://github.com/Lxtharia/minegrub-theme|github|minegrub|Minecraft main menu|Minecraft главное меню|gaming"
    "Minegrub Combined|https://github.com/Lxtharia/double-minegrub-menu|github-script|minegrub|Double Minecraft menu|Двойное меню Minecraft|gaming"
    "Minegrub World Select|https://github.com/Lxtharia/minegrub-world-sel-theme|github|minegrub-world-selection|Minecraft world select|Minecraft выбор мира|gaming"
    "Grubphemous|https://github.com/pvtoari/grubphemous-theme|github|grubphemous|Blasphemous style|Стиль Blasphemous|gaming"
    "DOOM|https://github.com/Lxtharia/doomgrub-theme|github|doomgrub|DOOM style|Стиль DOOM|gaming"
    "Hollow Grub|https://github.com/sergoncano/hollow-knight-grub-theme|github|hollow-knight|Hollow Knight theme|Тема Hollow Knight|gaming"
    "GrubSouls|https://github.com/PedroMMarinho/grubsouls-theme|github|grubsouls|Dark Souls theme|Тема Dark Souls|gaming"
    "Grubnautica|https://github.com/tatounee/Grubnautica|github|Grubnautica|Subnautica theme|Тема Subnautica|gaming"
    "ULTRAKILL|https://www.pling.com/p/2217746|pling|ultrakill|ULTRAKILL theme|Тема ULTRAKILL|gaming"
    "Crossgrub|https://github.com/krypciak/crossgrub|github|crossgrub|CrossCode theme|Тема CrossCode|gaming"
    "CelesteGRUB|https://github.com/suilven641/CelesteGRUB|github|CelesteGRUB|Celeste theme|Тема Celeste|gaming"
    "Lobotomy GRUB|https://github.com/rats-scamper/LoboGrubTheme|github|lobogrub|Lobotomy Corporation|Lobotomy Corporation|gaming"
    "Sekiro|https://github.com/semimqmo/sekiro_grub_theme|github|sekiro|Sekiro theme|Тема Sekiro|gaming"

    "CyberGRUB-2077|https://github.com/adnksharp/CyberGRUB-2077|github|CyberGRUB-2077|Cyberpunk 2077|Cyberpunk 2077|cyberpunk"
    "Cyberpunk 2077|https://www.pling.com/p/1515662|pling|cyberpunk2077|Official Cyberpunk|Официальный Cyberpunk|cyberpunk"
    "CyberRe|https://www.pling.com/p/1420727|pling|cyberre|Cyber-retro|Кибер-ретро|cyberpunk"
    "Virtuaverse|https://github.com/Patato777/dotfiles|github-subfolder|grub|Pixel cyberpunk|Пиксельный киберпанк|cyberpunk"
    "CRT-Amber|https://www.pling.com/p/1727268|pling|crt-amber|Retro CRT monitor|Ретро CRT монитор|cyberpunk"
    "OldBIOS|https://www.pling.com/p/2072033|pling|oldbios|Old BIOS style|Старый BIOS|cyberpunk"
    "Matrix-Morpheus|https://github.com/Priyank-Adhav/Matrix-Morpheus-GRUB-Theme|github|Matrix-Morpheus|Matrix theme|Тема Матрица|cyberpunk"

    "YoRHa|https://github.com/OliveThePuffin/yorha-grub-theme|github|yorha|NieR: Automata|NieR: Automata|anime"
    "Persona 5 Royal|https://www.pling.com/p/2122684|pling|persona5|Persona 5 Royal|Persona 5 Royal|anime"
    "Wuthering Waves|https://www.pling.com/p/2184155|pling|wuthering-waves|Wuthering Waves|Wuthering Waves|anime"
    "Grubshin Bootpact|https://github.com/max-ishere/grubshin-bootpact|github-installer|grubshin|Genshin Impact|Genshin Impact|anime"
    "VA-11 HALL-A|https://github.com/happyzxzxz/valhallaDots|github-subfolder|grub|VA-11 HALL-A bar|VA-11 HALL-A бар|anime"
    "Milk Outside|https://www.pling.com/p/2296341|pling|milk|Milk Outside A Bag|Milk Outside A Bag|anime"

    "Catppuccin|https://github.com/catppuccin/grub|github-installer|catppuccin|Pastel theme|Пастельная тема|minimal"
    "Sleek|https://www.pling.com/p/1414997|pling|sleek|Elegant theme|Элегантная тема|minimal"
    "HyperFluent|https://www.pling.com/p/2133341|pling|hyperfluent|Windows 11 style|Стиль Windows 11|minimal"
    "Elegant|https://github.com/vinceliuice/Elegant-grub2-themes|github-installer|Elegant|Elegant set|Элегантный набор|minimal"
    "Modern Design|https://github.com/vinceliuice/grub2-themes|github-installer|grub2-themes|Modern design|Современный дизайн|minimal"
    "Graphite|https://www.pling.com/p/1676418|pling|graphite|Graphite theme|Графитовая|minimal"
    "Neumorphic|https://www.pling.com/p/1906415|pling|neumorphic|Neumorphism|Неоморфизм|minimal"
    "Breeze|https://www.pling.com/p/1000111|pling|breeze|KDE Breeze|KDE Breeze|minimal"
    "Solarized-Dark|https://www.pling.com/p/1177401|pling|solarized-dark|Solarized Dark|Solarized Dark|minimal"
    "Framework|https://github.com/HeinrichZurHorstMeyer/Framework-Grub-Theme|github|Framework|Framework Laptop|Framework Laptop|minimal"

    "Space Isolation|https://github.com/callmenoodles/space-isolation|github|space-isolation|Space isolation|Космическая изоляция|scifi"
    "Descent|https://www.pling.com/p/1000083|pling|descent|Classic Descent|Классический Descent|scifi"
    "SteamOS|https://github.com/LegendaryBibo/Steam-Big-Picture-Grub-Theme|github|steam|Steam Big Picture|Steam Big Picture|scifi"

    "DedSec|https://www.pling.com/p/1569525|pling|dedsec|Watch Dogs DedSec|Watch Dogs DedSec|other"
    "Dark Matter|https://www.pling.com/p/1603282|pling|dark-matter|Dark matter|Тёмная материя|other"
    "Fallout|https://www.pling.com/p/1230882|pling|fallout|Fallout theme|Тема Fallout|other"
    "BSOL|https://github.com/harishnkr/bsol|github|bsol|Blue Screen of Linux|Blue Screen of Linux|other"
    "Grand Theft Gentoo|https://gitlab.com/imnotpua/grub_gtg|gitlab|gtg|GTA style|Стиль GTA|other"
    "LiquidGlass|https://github.com/Purp1eDuck2008/Liquid-GRUB|github|LiquidGlass|Glass effect|Стеклянный эффект|other"
)

update_themes() {
    print_header
    print_info "${L[updating_list]}"

    local readme_url="https://raw.githubusercontent.com/Jacksaur/Gorgeous-GRUB/main/README.md"
    local temp_readme="$TEMP_DIR/README.md"

    mkdir -p "$TEMP_DIR"

    if $USE_GUM; then
        gum spin --spinner dot --title "${L[updating_list]}" -- \
            curl -sL "$readme_url" -o "$temp_readme"
    else
        curl -sL "$readme_url" -o "$temp_readme"
    fi

    if [ ! -f "$temp_readme" ]; then
        print_error "${L[update_failed]}"
        sleep 2
        return 1
    fi

    mkdir -p "$CONFIG_DIR"
    local temp_db="$TEMP_DIR/themes.tmp"
    : > "$temp_db"

    grep -oP '\[\*\*.*?\*\*\]\(.*?\)' "$temp_readme" | while read -r match; do
        if [[ "$match" =~ \[\*\*([^\*]+)\*\*\]\(([^\)]+)\) ]]; then
            local name="${BASH_REMATCH[1]}"
            local url="${BASH_REMATCH[2]}"
            local type="github"
            local folder=""

            if [[ "$url" =~ ^(https://github\.com/[^/]+/[^/]+)/tree/[^/]+/(.+)$ ]]; then
                type="github-subfolder"
                local full_repo_url="${BASH_REMATCH[1]}"
                folder="${BASH_REMATCH[2]}"
                url="$full_repo_url"
            elif [[ "$url" == *"pling.com"* ]]; then
                type="pling"
            elif [[ "$url" == *"gitlab.com"* ]]; then
                type="gitlab"
            fi

            echo "$name|$url|$type|$folder|$name|$name|other" >> "$temp_db"
        fi
    done

    awk -F'|' '!seen[$1]++' "$temp_db" > "$THEMES_DB"
    local count=$(wc -l < "$THEMES_DB")

    rm -f "$temp_readme" "$temp_db"

    print_success "${L[list_updated]} ($count themes)"
    if $USE_GUM; then
        gum input --placeholder "${L[press_enter]}" > /dev/null
    else
        read -p "${L[press_enter]}"
    fi

    load_themes
}

load_themes() {
    THEMES=()
    if [ -f "$THEMES_DB" ] && [ -s "$THEMES_DB" ]; then
        mapfile -t THEMES < "$THEMES_DB"
    else
        THEMES=("${DEFAULT_THEMES[@]}")
    fi
}

get_theme_desc() {
    local theme_data=$1
    IFS='|' read -r name url type folder desc_en desc_ru category <<< "$theme_data"
    if [ "$LANG_CODE" == "ru" ]; then
        echo "$desc_ru"
    else
        echo "$desc_en"
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 🎨 UI Functions
# ════════════════════════════════════════════════════════════════════════════

print_header() {
    if $USE_GUM; then
        clear
        gum style \
            --border double \
            --border-foreground 212 \
            --padding "1 3" \
            --margin "1" \
            --align center \
            "🎨 $(gum style --foreground 212 --bold "${L[title]}")" \
            "" \
            "$(gum style --foreground 245 "${L[subtitle]}")"
    else
        clear
        echo -e "${PURPLE}"
        echo "╔═══════════════════════════════════════════════════════════════════════════╗"
        echo "║                      🎨 ${L[title]}                          ║"
        echo "║              ${L[subtitle]}                         ║"
        echo "╚═══════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    fi
}

print_success() {
    if $USE_GUM; then
        gum style --foreground 10 "✓ $1"
    else
        echo -e "${GREEN}✓ $1${NC}"
    fi
}

print_error() {
    if $USE_GUM; then
        gum style --foreground 9 "✗ $1"
    else
        echo -e "${RED}✗ $1${NC}"
    fi
}

print_warning() {
    if $USE_GUM; then
        gum style --foreground 11 "⚠ $1"
    else
        echo -e "${YELLOW}⚠ $1${NC}"
    fi
}

print_info() {
    if $USE_GUM; then
        gum style --foreground 12 "ℹ $1"
    else
        echo -e "${CYAN}ℹ $1${NC}"
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 🧹 Cleanup Functions
# ════════════════════════════════════════════════════════════════════════════

cleanup_double_menu() {
    print_info "${L[disable_double]}..."

    sudo grub-editenv - unset config_file 2>/dev/null || true

    sudo rm -f /etc/grub.d/05_twomenus 2>/dev/null || true
    sudo rm -f /boot/grub/mainmenu.cfg 2>/dev/null || true
    sudo rm -f /boot/grub2/mainmenu.cfg 2>/dev/null || true

    print_info "${L[updating_grub]}"
    if $USE_GUM; then
        gum spin --spinner dot --title "${L[updating_grub]}" -- \
            sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg 2>/dev/null
    else
        sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg 2>/dev/null
    fi

    print_success "${L[double_disabled]}"

    if $USE_GUM; then
        gum input --placeholder "${L[press_enter]}" > /dev/null
    else
        read -p "${L[press_enter]}"
    fi

}

reset_to_default() {
    print_header
    print_info "Resetting to default settings..."

    sudo sed -i '/^GRUB_THEME=/d' "$GRUB_CONFIG"

    print_info "Clearing GRUB cache..."
    sudo grub-editenv - unset theme
    sudo grub-editenv - unset config_file
    sudo grub-editenv - unset menu_auto_hide

    if grep -q "^GRUB_TIMEOUT_STYLE=hidden" "$GRUB_CONFIG"; then
         sudo sed -i 's/^GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/' "$GRUB_CONFIG"
    fi

    print_info "${L[updating_grub]}"

    if ! sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg; then
        print_error "Failed to update GRUB config"
    fi

    print_success "${L[reset_complete]}"
    print_info "${L[reboot_msg]}"

    if $USE_GUM; then
        gum input --placeholder "${L[press_enter]}" > /dev/null
    else
        read -p "${L[press_enter]}"
    fi
}

set_grub_language() {
    print_header

    local current_lang=$(grep "^GRUB_LANG=" "$GRUB_CONFIG" 2>/dev/null | cut -d'=' -f2 | tr -d '"')

    if $USE_GUM; then
        echo ""
        gum style --foreground 212 --bold "🌐 ${L[grub_lang]}"
        gum style --foreground 245 "Current: ${current_lang:-system}"
        gum style --foreground 11 "${L[grub_lang_note]}"
        echo ""

        local selected
        selected=$(printf "English (en)\nРусский (ru)" | gum choose \
            --cursor "▸ " \
            --cursor.foreground 212)

        if [ -z "$selected" ]; then
            return
        fi

        local new_lang=""
        case "$selected" in
            "English (en)") new_lang="en" ;;
            "Русский (ru)") new_lang="ru" ;;
        esac

        if [ -n "$new_lang" ]; then
            sudo sed -i '/^GRUB_LANG=/d' "$GRUB_CONFIG"
            echo "GRUB_LANG=$new_lang" | sudo tee -a "$GRUB_CONFIG" > /dev/null

            if [ "$new_lang" == "en" ]; then
                sudo rm -f /boot/$GRUB_PREFIX/locale/ru.mo 2>/dev/null || true
            fi

            gum spin --spinner dot --title "${L[updating_grub]}" -- \
                sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg 2>/dev/null

            print_success "${L[grub_lang_set]} $new_lang"
            gum input --placeholder "${L[press_enter]}" > /dev/null
        fi
    else
        echo -e "${BOLD}🌐 ${L[grub_lang]}:${NC}\n"
        echo -e "Current: ${CYAN}${current_lang:-system}${NC}"
        echo -e "${YELLOW}${L[grub_lang_note]}${NC}\n"

        echo -e "  ${CYAN}1${NC}) English (en)"
        echo -e "  ${CYAN}2${NC}) Русский (ru)"
        echo -e "\n  ${CYAN}0${NC}) ← Back"
        echo ""
        read -p "> " choice

        local new_lang=""
        case $choice in
            1) new_lang="en" ;;
            2) new_lang="ru" ;;
            0) return ;;
        esac

        if [ -n "$new_lang" ]; then
            sudo sed -i '/^GRUB_LANG=/d' "$GRUB_CONFIG"
            echo "GRUB_LANG=$new_lang" | sudo tee -a "$GRUB_CONFIG" > /dev/null

            if [ "$new_lang" == "en" ]; then
                sudo rm -f /boot/$GRUB_PREFIX/locale/ru.mo 2>/dev/null || true
            fi

            sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg 2>/dev/null
            print_success "${L[grub_lang_set]} $new_lang"
            read -p "${L[press_enter]}"
        fi
    fi
}

fix_theme_fonts() {
    print_header

    local current_theme_path=$(grep "^GRUB_THEME=" "$GRUB_CONFIG" 2>/dev/null | cut -d'=' -f2 | tr -d '"')

    if [ -z "$current_theme_path" ] || [ ! -f "$current_theme_path" ]; then
        print_error "${L[no_theme_applied]}"
        sleep 2
        return
    fi

    local theme_dir=$(dirname "$current_theme_path")
    local theme_name=$(basename "$theme_dir")

    local current_font_raw=$(grep -E "^(\s+)?font =" "$current_theme_path" | head -1 | cut -d'"' -f2)
    local current_font_display=$(echo "$current_font_raw" | sed 's/ [0-9]*$//')
    [ -z "$current_font_display" ] && current_font_display="Unknown"

    declare -A FONT_PATHS
    local font_names=()

    while IFS= read -r line; do
        local path=$(echo "$line" | cut -d: -f1)
        local name=$(echo "$line" | cut -d: -f2 | sed 's/^ *//' | cut -d',' -f1)

        [ -z "$name" ] && continue
        [[ "$path" != *.ttf && "$path" != *.otf && "$path" != *.ttc ]] && continue
        [[ -v "FONT_PATHS[$name]" ]] && continue

        FONT_PATHS["$name"]="$path"
        font_names+=("$name")
    done < <(fc-list --format="%{file}:%{family}\n" 2>/dev/null | sort -t: -k2 -u)

    if [ ${#font_names[@]} -eq 0 ]; then
        print_error "No fonts found"
        sleep 2
        return
    fi

    local selected=""
    local font_path=""

    if $USE_GUM; then
        echo ""
        gum style --foreground 212 --bold "🔤 ${L[fix_fonts]}"
        gum style --foreground 245 "Theme: $theme_name"
        gum style --foreground 245 "Current font: $current_font_display"
        echo ""

        selected=$(printf '%s\n' "${font_names[@]}" | gum filter \
            --placeholder "${L[search_placeholder]}" \
            --height 15 \
            --indicator "▸" \
            --indicator.foreground 212)

        [ -z "$selected" ] && return
        font_path="${FONT_PATHS[$selected]}"
    else
        echo -e "${BOLD}🔤 ${L[fix_fonts]}:${NC}\n"
        echo -e "Theme: ${CYAN}$theme_name${NC}"
        echo -e "Current font: ${CYAN}$current_font_display${NC}\n"
        echo -e "Enter font name to search (or number from list):\n"

        local idx=1
        for font in "${font_names[@]:0:20}"; do
            echo -e "  ${CYAN}$idx${NC}) $font"
            ((idx++))
        done
        [ ${#font_names[@]} -gt 20 ] && echo -e "  ... and $((${#font_names[@]} - 20)) more"

        echo -e "\n  ${CYAN}0${NC}) ← Back"
        echo ""
        read -p "> " choice

        [ "$choice" == "0" ] || [ -z "$choice" ] && return

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#font_names[@]} ]; then
            selected="${font_names[$((choice-1))]}"
            font_path="${FONT_PATHS[$selected]}"
        else
            for name in "${font_names[@]}"; do
                if [[ "${name,,}" == *"${choice,,}"* ]]; then
                    selected="$name"
                    font_path="${FONT_PATHS[$selected]}"
                    break
                fi
            done
        fi
    fi

    if [ -z "$font_path" ] || [ ! -f "$font_path" ]; then
        print_error "Font not found: $selected"
        sleep 2
        return
    fi

    print_info "Selected: $selected"
    print_info "Path: $font_path"

    sudo -v || return

    print_info "Creating .pf2 fonts (this may take a moment)..."

    local font_file_20="$theme_dir/grub-font-20.pf2"
    local font_file_30="$theme_dir/grub-font-30.pf2"

    sudo rm -f "$font_file_20" "$font_file_30"

    local mkfont_output=""

    sudo grub-mkfont -v -n "$selected" -s 20 -o "$font_file_20" "$font_path" >/dev/null 2>&1 || true
    mkfont_output=$(sudo grub-mkfont -v -n "$selected" -s 30 -o "$font_file_30" "$font_path" 2>&1)

    if [ ! -f "$font_file_30" ]; then
        echo "$mkfont_output"
        print_error "Failed to create font file"
        sleep 2
        return
    fi

    local grub_font_name=$(echo "$mkfont_output" | grep "Font name:" | head -1 | cut -d: -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -z "$grub_font_name" ]; then
        local strings_output=$(strings "$font_file_30" 2>/dev/null)
        grub_font_name=$(echo "$strings_output" | grep -A1 "^PFF2NAME$" | tail -1)

        if [ -z "$grub_font_name" ] || [ "$grub_font_name" == "PFF2NAME" ]; then
             grub_font_name=$(echo "$strings_output" | grep -A1 "^NAME$" | tail -1)
        fi
        grub_font_name=$(echo "$grub_font_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi

    [ -z "$grub_font_name" ] && grub_font_name="$selected 30"

    print_info "GRUB font name: '$grub_font_name'"

    print_info "Updating theme.txt..."

    sudo sed -i -E "s/(font *= *\")[^\"]+(\")/\1${grub_font_name}\2/g" "$current_theme_path"
    sudo sed -i -E "s/(item_font *= *\")[^\"]+(\")/\1${grub_font_name}\2/g" "$current_theme_path"

    echo ""
    print_info "Verification:"
    grep -E "font|item_font" "$current_theme_path" | head -4
    echo ""

    print_success "${L[font_replaced]}: $grub_font_name"
    print_info "${L[reboot_msg]}"

    if $USE_GUM; then
        gum input --placeholder "${L[press_enter]}" > /dev/null
    else
        read -p "${L[press_enter]}"
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 🔧 System Functions
# ════════════════════════════════════════════════════════════════════════════

check_dependencies() {
    local missing=()
    for cmd in git sudo; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        print_error "${L[dependencies_missing]}: ${missing[*]}"
        exit 1
    fi
}

detect_grub() {
    if [ -d "/boot/grub" ]; then
        GRUB_PREFIX="grub"
        GRUB_THEMES_DIR="/boot/grub/themes"
    elif [ -d "/boot/grub2" ]; then
        GRUB_PREFIX="grub2"
        GRUB_THEMES_DIR="/boot/grub2/themes"
    else
        print_error "${L[grub_not_found]}"
        exit 1
    fi
}

get_current_theme() {
    if [ -f "$GRUB_CONFIG" ]; then
        local theme=$(grep "^GRUB_THEME=" "$GRUB_CONFIG" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
        if [ -n "$theme" ]; then
            basename "$(dirname "$theme")"
        else
            echo "-"
        fi
    else
        echo "-"
    fi
}

get_installed_themes() {
    local themes=()
    if [ -d "$GRUB_THEMES_DIR" ]; then
        for theme_dir in "$GRUB_THEMES_DIR"/*/; do
            if [ -f "$theme_dir/theme.txt" ]; then
                themes+=("$(basename "$theme_dir")")
            fi
        done
    fi
    echo "${themes[@]}"
}

# ════════════════════════════════════════════════════════════════════════════
# 📦 Installation Functions
# ════════════════════════════════════════════════════════════════════════════

install_github_theme() {
    local url=$1
    local folder=$2
    local name=$3

    print_info "${L[cloning]} $url"
    local log_file="$TEMP_DIR/clone.log"

    if $USE_GUM; then
        gum spin --spinner dot --title "${L[cloning]}" -- \
            bash -c "git clone --depth 1 \"$url.git\" repo > \"$log_file\" 2>&1"
    else
        git clone --depth 1 "$url.git" repo > "$log_file" 2>&1
    fi

    if [ $? -ne 0 ]; then
        print_error "${L[clone_failed]}"
        echo -e "${RED}Error details:${NC}"
        cat "$log_file"
        return 1
    fi

    if [ -f "repo/install.sh" ]; then
        print_info "${L[install_script]} (install.sh found)"
        cd repo
        chmod +x install.sh
        sudo bash install.sh
        cd ..
        print_success "${L[install_complete]}"
        return 0
    fi

    local theme_path=""
    theme_path=$(find repo -name "theme.txt" -printf "%h\n" 2>/dev/null | head -1)

    if [ -z "$theme_path" ]; then
        print_error "${L[theme_not_found]} (No install.sh or theme.txt)"
        return 1
    fi

    local theme_name=$(basename "$theme_path")
    print_info "${L[found_theme]}: $theme_name"

    sudo mkdir -p "$GRUB_THEMES_DIR"
    sudo cp -r "$theme_path" "$GRUB_THEMES_DIR/"

    apply_theme "$GRUB_THEMES_DIR/$theme_name/theme.txt"
}

install_github_script_theme() {
    local url=$1
    local name=$2

    print_info "${L[cloning]} $url"
    local log_file="$TEMP_DIR/clone.log"

    if $USE_GUM; then
        gum spin --spinner dot --title "${L[cloning]}" -- \
            bash -c "git clone --depth 1 \"$url.git\" repo > \"$log_file\" 2>&1"
    else
        git clone --depth 1 "$url.git" repo > "$log_file" 2>&1
    fi

    if [ $? -ne 0 ]; then
        print_error "${L[clone_failed]}"
        echo -e "${RED}Error details:${NC}"
        cat "$log_file"
        return 1
    fi

    cd repo

    if [ -f "install.sh" ]; then
        print_info "${L[install_script]}"
        sudo bash install.sh
        print_success "${L[install_complete]}"
    else
        print_error "install.sh not found"
        return 1
    fi
}

install_github_with_installer() {
    local url=$1
    local name=$2

    print_info "${L[cloning]} $url"
    local log_file="$TEMP_DIR/clone.log"

    if $USE_GUM; then
        gum spin --spinner dot --title "${L[cloning]}" -- \
            bash -c "git clone --depth 1 \"$url.git\" repo > \"$log_file\" 2>&1"
    else
        git clone --depth 1 "$url.git" repo > "$log_file" 2>&1
    fi

    if [ $? -ne 0 ]; then
        print_error "${L[clone_failed]}"
        echo -e "${RED}Error details:${NC}"
        cat "$log_file"
        return 1
    fi

    cd repo

    if [ -f "install.sh" ]; then
        print_info "${L[install_script]}"
        sudo bash install.sh
        print_success "${L[install_complete]}"
    else
        cd ..
        install_github_theme "$url" "" "$name"
    fi
}

install_github_subfolder_theme() {
    local url=$1
    local folder=$2
    local name=$3

    print_info "${L[cloning]} $url"
    local log_file="$TEMP_DIR/clone.log"

    if $USE_GUM; then
        gum spin --spinner dot --title "${L[cloning]}" -- \
            bash -c "git clone --depth 1 \"$url.git\" repo > \"$log_file\" 2>&1"
    else
        git clone --depth 1 "$url.git" repo > "$log_file" 2>&1
    fi

    if [ $? -ne 0 ]; then
        print_error "${L[clone_failed]}"
        echo -e "${RED}Error details:${NC}"
        cat "$log_file"
        return 1
    fi

    if [ -d "repo/$folder" ]; then
        local theme_name=$(basename "$folder")
        sudo mkdir -p "$GRUB_THEMES_DIR"
        sudo cp -r "repo/$folder" "$GRUB_THEMES_DIR/$theme_name"

        if [ -f "$GRUB_THEMES_DIR/$theme_name/theme.txt" ]; then
            apply_theme "$GRUB_THEMES_DIR/$theme_name/theme.txt"
        else
            print_warning "${L[theme_not_found]}"
        fi
    else
        print_error "${L[folder_not_found]}: $folder"
        return 1
    fi
}

install_gitlab_theme() {
    local url=$1
    local folder=$2
    local name=$3

    print_info "${L[cloning]} $url"
    local log_file="$TEMP_DIR/clone.log"

    if $USE_GUM; then
        gum spin --spinner dot --title "${L[cloning]}" -- \
            bash -c "git clone --depth 1 \"$url.git\" repo > \"$log_file\" 2>&1"
    else
        git clone --depth 1 "$url.git" repo > "$log_file" 2>&1
    fi

    if [ $? -ne 0 ]; then
        print_error "${L[clone_failed]}"
        echo -e "${RED}Error details:${NC}"
        cat "$log_file"
        return 1
    fi

    local theme_path=""
    theme_path=$(find repo -name "theme.txt" -printf "%h\n" 2>/dev/null | head -1)

    if [ -z "$theme_path" ]; then
        print_error "${L[theme_not_found]}"
        return 1
    fi

    local theme_name=$(basename "$theme_path")
    sudo mkdir -p "$GRUB_THEMES_DIR"
    sudo cp -r "$theme_path" "$GRUB_THEMES_DIR/"

    apply_theme "$GRUB_THEMES_DIR/$theme_name/theme.txt"
}

install_pling_theme() {
    local url=$1
    local folder=$2
    local name=$3

    print_warning "${L[pling_manual]}"
    echo ""

    if $USE_GUM; then
        gum style --foreground 15 "${L[pling_instructions]} $(gum style --bold "$name"):"
        echo "  1. ${L[open_url]}: $(gum style --foreground 12 "$url")"
        echo "  2. ${L[download_archive]}"
        echo "  3. ${L[extract_to]}: $(gum style --foreground 12 "$GRUB_THEMES_DIR/")"
        echo "  4. ${L[run_again]}"
        echo ""

        if gum confirm "${L[open_browser]}"; then
            xdg-open "$url" 2>/dev/null &
        fi
    else
        echo -e "${L[pling_instructions]} ${BOLD}$name${NC}:"
        echo -e "  1. ${L[open_url]}: ${CYAN}$url${NC}"
        echo -e "  2. ${L[download_archive]}"
        echo -e "  3. ${L[extract_to]}: ${CYAN}$GRUB_THEMES_DIR/${NC}"
        echo -e "  4. ${L[run_again]}"
    fi
}

reboot_system() {
    print_header

    if $USE_GUM; then
        if gum confirm "${L[reboot]}?"; then
             sudo reboot
        fi
    else
        read -p "${L[reboot]}? [y/N]: " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            sudo reboot
        fi
    fi
}

sanitize_theme_paths() {
    local theme_dir=$1
    local theme_file="$theme_dir/theme.txt"

    if [ -f "$theme_file" ]; then
        sudo sed -i -E 's|/boot/grub/themes/[^/]+/||g' "$theme_file"
        sudo sed -i -E 's|/grub/themes/[^/]+/||g' "$theme_file"
    fi
}

apply_theme() {
    local theme_path=$1
    local theme_dir=$(dirname "$theme_path")

    sanitize_theme_paths "$theme_dir"

    print_info "${L[applying]}"

    sudo sed -i '/^GRUB_THEME=/d' "$GRUB_CONFIG"
    echo "GRUB_THEME=\"$theme_path\"" | sudo tee -a "$GRUB_CONFIG" > /dev/null

    if ! grep -q "^GRUB_TIMEOUT_STYLE=menu" "$GRUB_CONFIG"; then
        sudo sed -i '/^GRUB_TIMEOUT_STYLE=/d' "$GRUB_CONFIG"
        echo "GRUB_TIMEOUT_STYLE=menu" | sudo tee -a "$GRUB_CONFIG" > /dev/null
    fi

    print_info "${L[updating_grub]}"

    if $USE_GUM; then
        gum spin --spinner dot --title "${L[updating_grub]}" -- \
            sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg
    else
        sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg
    fi

    print_success "${L[success]}"
    print_info "${L[reboot_msg]}"
}

install_theme() {
    local idx=$1
    IFS='|' read -r name url type folder desc_en desc_ru category <<< "${THEMES[$idx]}"
    local desc=$(get_theme_desc "${THEMES[$idx]}")

    print_header

    if $USE_GUM; then
        gum style \
            --border rounded \
            --border-foreground 212 \
            --padding "1 2" \
            --margin "1" \
            "🔧 $name" \
            "" \
            "$(gum style --foreground 245 "$desc")"
    else
        echo -e "${BOLD}🔧 $name${NC}"
        echo -e "${WHITE}$desc${NC}\n"
    fi

    echo ""

    echo ""

    sudo rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    case $type in
        "github") install_github_theme "$url" "$folder" "$name" ;;
        "github-script") install_github_script_theme "$url" "$name" ;;
        "github-installer") install_github_with_installer "$url" "$name" ;;
        "github-subfolder") install_github_subfolder_theme "$url" "$folder" "$name" ;;
        "pling") install_pling_theme "$url" "$folder" "$name" ;;
        "gitlab") install_gitlab_theme "$url" "$folder" "$name" ;;
    esac

    cd /
    rm -rf "$TEMP_DIR"

    echo ""
    if $USE_GUM; then
        gum input --placeholder "${L[press_enter]}" > /dev/null
    else
        read -p "${L[press_enter]}"
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 🎮 Interactive Menu
# ════════════════════════════════════════════════════════════════════════════

select_theme_to_install() {
    print_header

    if $USE_GUM; then
        local options=()
        for theme_data in "${THEMES[@]}"; do
            IFS='|' read -r name url type folder desc_en desc_ru category <<< "$theme_data"
            local cat_name=$(get_category_name "$category")
            local desc=$(get_theme_desc "$theme_data")
            options+=("$cat_name  $name  •  $desc")
        done

        echo ""
        gum style --foreground 212 --bold "🎨 ${L[select_theme]}"
        gum style --foreground 245 "${L[use_arrows]}"
        echo ""

        local selected
        selected=$(printf '%s\n' "${options[@]}" | gum filter \
            --height 20 \
            --placeholder "${L[search_placeholder]}" \
            --indicator "▸" \
            --indicator.foreground 212 \
            --match.foreground 212)

        if [ -z "$selected" ]; then
            return
        fi

        local idx=0
        for theme_data in "${THEMES[@]}"; do
            IFS='|' read -r name url type folder desc_en desc_ru category <<< "$theme_data"
            local cat_name=$(get_category_name "$category")
            local desc=$(get_theme_desc "$theme_data")
            local check="$cat_name  $name  •  $desc"
            if [ "$check" == "$selected" ]; then
                install_theme $idx
                return
            fi
            ((idx++))
        done
    else
        echo -e "${BOLD}🎨 ${L[select_theme]}:${NC}\n"

        local idx=1
        for theme_data in "${THEMES[@]}"; do
            IFS='|' read -r name url type folder desc_en desc_ru category <<< "$theme_data"
            local desc=$(get_theme_desc "$theme_data")
            printf "  ${CYAN}%2d${NC}) %-20s ${WHITE}%s${NC}\n" "$idx" "$name" "$desc"
            ((idx++))
        done

        echo -e "\n  ${CYAN} 0${NC}) ← Back"
        echo ""
        read -p "> " choice

        if [ "$choice" == "0" ] || [ -z "$choice" ]; then
            return
        fi

        if [ "$choice" -ge 1 ] && [ "$choice" -le ${#THEMES[@]} ]; then
            install_theme $((choice - 1))
        fi
    fi
}

select_installed_theme() {
    print_header

    local themes=($(get_installed_themes))

    if [ ${#themes[@]} -eq 0 ]; then
        print_warning "${L[no_themes]}"
        sleep 2
        return
    fi

    if $USE_GUM; then
        echo ""
        gum style --foreground 212 --bold "✅ ${L[select_installed]}"
        echo ""

        local selected
        selected=$(printf '%s\n' "${themes[@]}" | gum choose \
            --cursor "▸ " \
            --cursor.foreground 212 \
            --selected.foreground 212)

        if [ -n "$selected" ]; then
            apply_theme "$GRUB_THEMES_DIR/$selected/theme.txt"
            gum input --placeholder "${L[press_enter]}" > /dev/null
        fi
    else
        echo -e "${BOLD}📦 ${L[select_installed]}:${NC}\n"

        local idx=1
        for theme in "${themes[@]}"; do
            echo -e "  ${CYAN}$idx${NC}) $theme"
            ((idx++))
        done

        echo -e "\n  ${CYAN}0${NC}) ← Back"
        echo ""
        read -p "> " choice

        if [ "$choice" == "0" ] || [ -z "$choice" ]; then
            return
        fi

        if [ "$choice" -ge 1 ] && [ "$choice" -le ${#themes[@]} ]; then
            apply_theme "$GRUB_THEMES_DIR/${themes[$((choice-1))]}/theme.txt"
            read -p "${L[press_enter]}"
        fi
    fi
}

remove_theme_menu() {
    print_header

    local themes=($(get_installed_themes))

    if [ ${#themes[@]} -eq 0 ]; then
        print_warning "${L[no_themes]}"
        sleep 2
        return
    fi

    if $USE_GUM; then
        echo ""
        gum style --foreground 9 --bold "🗑️ ${L[select_remove]}"
        echo ""

        local selected
        selected=$(printf '%s\n' "${themes[@]}" | gum choose \
            --cursor "▸ " \
            --cursor.foreground 9)

        if [ -n "$selected" ]; then
            if gum confirm "${L[confirm_remove]} '$selected'?"; then
                sudo rm -rf "$GRUB_THEMES_DIR/$selected"
                print_success "${L[removed]}: $selected"
            fi
            gum input --placeholder "${L[press_enter]}" > /dev/null
        fi
    else
        echo -e "${BOLD}🗑️ ${L[select_remove]}:${NC}\n"

        local idx=1
        for theme in "${themes[@]}"; do
            echo -e "  ${CYAN}$idx${NC}) $theme"
            ((idx++))
        done

        echo -e "\n  ${CYAN}0${NC}) ← Back"
        echo ""
        read -p "> " choice

        if [ "$choice" == "0" ] || [ -z "$choice" ]; then
            return
        fi

        if [ "$choice" -ge 1 ] && [ "$choice" -le ${#themes[@]} ]; then
            local selected="${themes[$((choice-1))]}"
            read -p "${L[confirm_remove]} '$selected'? [y/N]: " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                sudo rm -rf "$GRUB_THEMES_DIR/$selected"
                print_success "${L[removed]}"
            fi
            read -p "${L[press_enter]}"
        fi
    fi
}

set_resolution_menu() {
    print_header

    local current_res=$(grep "^GRUB_GFXMODE=" "$GRUB_CONFIG" 2>/dev/null | cut -d'=' -f2 | tr -d '"')

    if $USE_GUM; then
        echo ""
        gum style --foreground 212 --bold "🖥️ ${L[resolution_title]}"
        gum style --foreground 245 "${L[current_resolution]}: ${current_res:-auto}"
        echo ""

        local resolutions=("1920x1080" "2560x1440" "1366x768" "1280x720" "3840x2160" "auto" "${L[enter_manually]}")

        local selected
        selected=$(printf '%s\n' "${resolutions[@]}" | gum choose \
            --cursor "▸ " \
            --cursor.foreground 212)

        if [ -z "$selected" ]; then
            return
        fi

        local new_res="$selected"
        if [ "$selected" == "${L[enter_manually]}" ]; then
            new_res=$(gum input --placeholder "1920x1080")
        fi

        if [ -n "$new_res" ]; then
            sudo sed -i "s/^GRUB_GFXMODE=.*/GRUB_GFXMODE=$new_res/" "$GRUB_CONFIG"
            if ! grep -q "^GRUB_GFXMODE=" "$GRUB_CONFIG"; then
                echo "GRUB_GFXMODE=$new_res" | sudo tee -a "$GRUB_CONFIG" > /dev/null
            fi

            gum spin --spinner dot --title "${L[updating_grub]}" -- \
                sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg 2>/dev/null

            print_success "${L[resolution_set]}: $new_res"
            gum input --placeholder "${L[press_enter]}" > /dev/null
        fi
    else
        echo -e "${BOLD}🖥️ ${L[resolution_title]}:${NC}\n"
        echo -e "${L[current_resolution]}: ${CYAN}${current_res:-auto}${NC}\n"

        echo -e "  ${CYAN}1${NC}) 1920x1080"
        echo -e "  ${CYAN}2${NC}) 2560x1440"
        echo -e "  ${CYAN}3${NC}) 1366x768"
        echo -e "  ${CYAN}4${NC}) auto"
        echo -e "\n  ${CYAN}0${NC}) ← Back"
        echo ""
        read -p "> " choice

        local new_res=""
        case $choice in
            1) new_res="1920x1080" ;;
            2) new_res="2560x1440" ;;
            3) new_res="1366x768" ;;
            4) new_res="auto" ;;
            0) return ;;
        esac

        if [ -n "$new_res" ]; then
            sudo sed -i "s/^GRUB_GFXMODE=.*/GRUB_GFXMODE=$new_res/" "$GRUB_CONFIG"
            sudo grub-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg 2>/dev/null
            print_success "${L[resolution_set]}: $new_res"
            read -p "${L[press_enter]}"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# 🏠 Main Menu
# ════════════════════════════════════════════════════════════════════════════

main_menu() {
    while true; do
        print_header

        local current_theme=$(get_current_theme)
        local installed_themes=($(get_installed_themes))

        if $USE_GUM; then
            gum style --foreground 245 "${L[current_theme]}: $(gum style --foreground 212 --bold "$current_theme")"
            gum style --foreground 245 "${L[installed_themes]}: $(gum style --foreground 10 "${#installed_themes[@]}")"
            echo ""

            local options=(
                "🎨 ${L[install_new]}"
                "📡 ${L[rescan_themes]}"
                "✅ ${L[apply_installed]}"
                "🔄 ${L[reboot]}"
                "🗑️  ${L[remove_theme]}"
                "🖥️  ${L[set_resolution]}"
                "🔤 ${L[fix_fonts]}"
                "🌐 ${L[grub_lang]}"
                "🔄 ${L[disable_double]}"
                "🔙 ${L[reset_default]}"
                "🌍 ${L[change_language]}"
                "🚪 ${L[exit]}"
            )

            local selected
            selected=$(printf '%s\n' "${options[@]}" | gum choose \
                --cursor "▸ " \
                --cursor.foreground 212 \
                --selected.foreground 212 \
                --height 11)

            case "$selected" in
                "🎨 ${L[install_new]}") select_theme_to_install ;;
                "📡 ${L[rescan_themes]}") update_themes ;;
                "✅ ${L[apply_installed]}") select_installed_theme ;;
                "🔄 ${L[reboot]}") reboot_system ;;
                "🗑️  ${L[remove_theme]}") remove_theme_menu ;;
                "🖥️  ${L[set_resolution]}") set_resolution_menu ;;
                "🔤 ${L[fix_fonts]}") fix_theme_fonts ;;
                "🌐 ${L[grub_lang]}") set_grub_language ;;
                "🔄 ${L[disable_double]}") cleanup_double_menu ;;
                "🔙 ${L[reset_default]}") reset_to_default ;;
                "🌍 ${L[change_language]}") select_language ;;
                "🚪 ${L[exit]}")
                    echo ""
                    gum style --foreground 10 "${L[goodbye]} 👋"
                    exit 0
                    ;;
            esac
        else
            echo -e "${WHITE}${L[current_theme]}: ${CYAN}$current_theme${NC}"
            echo -e "${WHITE}${L[installed_themes]}: ${GREEN}${#installed_themes[@]}${NC}\n"

            echo -e "${BOLD}Menu:${NC}"
            echo -e "  ${CYAN}1${NC}) 🎨 ${L[install_new]}"
            echo -e "  ${CYAN}u${NC}) 📡 ${L[rescan_themes]}"
            echo -e "  ${CYAN}2${NC}) ✅ ${L[apply_installed]}"
            echo -e "  ${CYAN}3${NC}) 🗑️  ${L[remove_theme]}"
            echo -e "  ${CYAN}r${NC}) 🔄 ${L[reboot]}"
            echo -e "  ${CYAN}4${NC}) 🖥️  ${L[set_resolution]}"
            echo -e "  ${CYAN}5${NC}) 🔤 ${L[fix_fonts]}"
            echo -e "  ${CYAN}6${NC}) 🌐 ${L[grub_lang]}"
            echo -e "  ${CYAN}7${NC}) 🔄 ${L[disable_double]}"
            echo -e "  ${CYAN}8${NC}) 🔙 ${L[reset_default]}"
            echo -e "  ${CYAN}9${NC}) 🌍 ${L[change_language]}"
            echo -e "  ${CYAN}0${NC}) 🚪 ${L[exit]}"
            echo ""
            read -p "> " action

            case $action in
                1) select_theme_to_install ;;
                u) update_themes ;;
                2) select_installed_theme ;;
                r) reboot_system ;;
                3) remove_theme_menu ;;
                4) set_resolution_menu ;;
                5) fix_theme_fonts ;;
                6) set_grub_language ;;
                7) cleanup_double_menu ;;
                8) reset_to_default ;;
                9) select_language ;;
                0)
                    echo -e "\n${GREEN}${L[goodbye]} 👋${NC}\n"
                    exit 0
                    ;;
            esac
        fi
    done
}

# ════════════════════════════════════════════════════════════════════════════
# 📖 CLI Mode
# ════════════════════════════════════════════════════════════════════════════

show_help() {
    echo -e "${BOLD}🎨 Gorgeous GRUB Installer${NC}"
    echo ""
    echo "Usage:"
    echo "  ./gorgeous-grub.sh              Interactive mode"
    echo "  ./gorgeous-grub.sh --list       List all themes"
    echo "  ./gorgeous-grub.sh --search Q   Search theme"
    echo "  ./gorgeous-grub.sh --install N  Install theme"
    echo "  ./gorgeous-grub.sh --lang ru    Set language (en/ru)"
    echo "  ./gorgeous-grub.sh --help       This help"
    echo ""
}

list_all_themes() {
    echo -e "${BOLD}🎨 Available themes:${NC}\n"

    local idx=1
    for theme_data in "${THEMES[@]}"; do
        IFS='|' read -r name url type folder desc_en desc_ru category <<< "$theme_data"
        local desc=$(get_theme_desc "$theme_data")
        local cat_name=$(get_category_name "$category")
        printf "  ${CYAN}%2d${NC}) %-22s ${WHITE}%-30s${NC} ${PURPLE}%s${NC}\n" "$idx" "$name" "$desc" "$cat_name"
        ((idx++))
    done

    echo ""
    echo -e "Use: ${CYAN}./gorgeous-grub.sh --install \"Name\"${NC}"
}

search_theme() {
    local query=$1
    echo -e "${BOLD}🔍 Search: $query${NC}\n"

    local found=0
    local idx=1
    for theme_data in "${THEMES[@]}"; do
        IFS='|' read -r name url type folder desc_en desc_ru category <<< "$theme_data"
        local desc=$(get_theme_desc "$theme_data")
        if echo "$name $desc_en $desc_ru" | grep -iq "$query"; then
            printf "  ${CYAN}%2d${NC}) %-22s ${WHITE}%s${NC}\n" "$idx" "$name" "$desc"
            found=1
        fi
        ((idx++))
    done

    [ $found -eq 0 ] && echo -e "  ${YELLOW}Not found${NC}"
}

install_by_name() {
    local query=$1

    local idx=0
    for theme_data in "${THEMES[@]}"; do
        IFS='|' read -r name url type folder desc_en desc_ru category <<< "$theme_data"
        if echo "$name" | grep -iq "^$query$" || echo "$name" | grep -iq "$query"; then
            print_info "Found: $name"
            install_theme $idx
            return 0
        fi
        ((idx++))
    done

    print_error "Theme '$query' not found"
    echo "Use --list to see available themes"
    exit 1
}

# ════════════════════════════════════════════════════════════════════════════
# 🚀 Entry Point
# ════════════════════════════════════════════════════════════════════════════

load_config
load_language
load_themes

check_dependencies
detect_grub

# First run - ask for language
if [ ! -f "$CONFIG_FILE" ]; then
    if $USE_GUM; then
        clear
        gum style \
            --border double \
            --border-foreground 212 \
            --padding "1 3" \
            --margin "1" \
            --align center \
            "🎨 Gorgeous GRUB Installer" \
            "" \
            "🌍 Select language / Выберите язык"
        echo ""
        select_language
    else
        echo ""
        echo "🌍 Select language / Выберите язык"
        select_language
    fi
fi

case "${1:-}" in
    --help|-h) show_help; exit 0 ;;
    --list|-l) list_all_themes; exit 0 ;;
    --search|-s)
        [ -z "${2:-}" ] && { print_error "Specify query"; exit 1; }
        search_theme "$2"; exit 0 ;;
    --install|-i)
        [ -z "${2:-}" ] && { print_error "Specify theme name"; exit 1; }
        install_by_name "$2"; exit 0 ;;
    --lang)
        [ -z "${2:-}" ] && { print_error "Specify language (en/ru)"; exit 1; }
        LANG_CODE="$2"
        save_config
        load_language
        print_success "${L[language_saved]}: $LANG_CODE"
        exit 0 ;;
    "") main_menu ;;
    *) print_error "Unknown argument: $1"; show_help; exit 1 ;;
esac
