"""Neofetch Theme Management Module.

Manages themes from the Chick2D/neofetch-themes collection.
Provides status queries and actions for the TUI.
"""

import filecmp
import hashlib
import os
import shutil
import subprocess
from pathlib import Path

from . import DOTFILES_DIR, SCRIPTS_DIR

NEOFETCH_CONFIG = Path.home() / ".config" / "neofetch" / "config.conf"
NEOFETCH_BACKUP = Path.home() / ".config" / "neofetch" / "config.conf.bak"
THEMES_DIR = DOTFILES_DIR / "neofetch-themes"


def _discover_themes() -> list[dict]:
    """Discover all available themes from local neofetch-themes directory."""
    themes = []
    if not THEMES_DIR.is_dir():
        return themes

    for category in ["normal", "small"]:
        cat_dir = THEMES_DIR / category
        if not cat_dir.is_dir():
            continue
        for entry in sorted(cat_dir.iterdir()):
            name = entry.stem if entry.suffix == ".conf" else entry.name
            config_path = entry if entry.suffix == ".conf" else entry / "config.conf"
            if config_path.is_file():
                themes.append({
                    "name": name,
                    "category": category,
                    "path": config_path,
                })
    return themes


def _file_md5(path: Path) -> str:
    try:
        return hashlib.md5(path.read_bytes()).hexdigest()
    except (OSError, PermissionError):
        return ""


def get_current_theme() -> str:
    """Detect which theme is currently applied by checksum or header."""
    if not NEOFETCH_CONFIG.is_file():
        return "none"

    current_md5 = _file_md5(NEOFETCH_CONFIG)

    for theme in _discover_themes():
        if theme["path"].is_file() and _file_md5(theme["path"]) == current_md5:
            return theme["name"]

    try:
        for line in NEOFETCH_CONFIG.read_text().splitlines():
            if line.startswith("# Neofetch Theme:"):
                return line.split(":", 1)[1].strip()
    except (OSError, PermissionError):
        pass

    return "custom"


def get_status() -> dict:
    """Return current theme info and theme counts."""
    themes = _discover_themes()
    normal = [t for t in themes if t["category"] == "normal"]
    small = [t for t in themes if t["category"] == "small"]
    return {
        "current": get_current_theme(),
        "total": len(themes),
        "normal_count": len(normal),
        "small_count": len(small),
        "normal": normal,
        "small": small,
    }


def apply_theme(name: str) -> str:
    """Apply a theme by name (exact or partial match)."""
    themes = _discover_themes()
    theme = next((t for t in themes if t["name"].lower() == name.lower()), None)

    if not theme:
        theme = next(
            (t for t in themes if name.lower() in t["name"].lower()), None
        )

    if not theme:
        available = ", ".join(t["name"] for t in themes[:10])
        return f"Theme '{name}' not found. Available: {available}..."

    config_dir = NEOFETCH_CONFIG.parent
    config_dir.mkdir(parents=True, exist_ok=True)

    if NEOFETCH_CONFIG.is_file():
        shutil.copy2(NEOFETCH_CONFIG, NEOFETCH_BACKUP)

    shutil.copy2(theme["path"], NEOFETCH_CONFIG)

    header = f"# Neofetch Theme: {theme['name']}\n"
    raw = NEOFETCH_CONFIG.read_text()
    if not raw.startswith("# Neofetch Theme:"):
        NEOFETCH_CONFIG.write_text(header + raw)

    return f"Applied: {theme['name']} ({theme['category']})"


def list_themes() -> str:
    """Return formatted list of themes for display."""
    status = get_status()
    lines = [f"Current: {status['current']}", ""]

    for category in ["normal", "small"]:
        items = [t for t in status[category]]
        if not items:
            continue
        lines.append(f"▸ {category.capitalize()}:")
        for t in items:
            marker = "●" if t["name"] == status["current"] else " "
            lines.append(f"  {marker} {t['name']}")
        lines.append("")

    lines.append(f"Total: {status['total']} themes")
    return "\n".join(lines)


def backup_config() -> str:
    """Backup current neofetch config."""
    if not NEOFETCH_CONFIG.is_file():
        return "No config to backup."
    shutil.copy2(NEOFETCH_CONFIG, NEOFETCH_BACKUP)
    return f"Backed up to {NEOFETCH_BACKUP}"


def restore_config() -> str:
    """Restore neofetch config from backup."""
    if not NEOFETCH_BACKUP.is_file():
        return "No backup found."
    shutil.copy2(NEOFETCH_BACKUP, NEOFETCH_CONFIG)
    return "Restored from backup."
