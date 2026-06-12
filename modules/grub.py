"""GRUB Theme Management Module.

Wraps the Gorgeous GRUB bash installer as a Python API.
Provides status queries and action functions for the TUI.
"""

import os
import re
import shutil
import subprocess
from pathlib import Path

from . import SCRIPTS_DIR

GRUB_CONFIG = Path("/etc/default/grub")
GRUB_THEMES_DIRS = [Path("/boot/grub/themes"), Path("/boot/grub2/themes")]
GRUB_BINARY = "grub-mkconfig"


def _get_grub_prefix() -> str:
    """Return 'grub' or 'grub2' depending on the system."""
    if Path("/boot/grub2").is_dir():
        return "grub2"
    return "grub"


def get_grub_themes_dir() -> Path | None:
    for d in GRUB_THEMES_DIRS:
        if d.is_dir():
            return d
    return None


def get_current_theme() -> str:
    """Return the basename of the currently applied GRUB theme, or '-'."""
    if not GRUB_CONFIG.is_file():
        return "-"
    try:
        for line in GRUB_CONFIG.read_text().splitlines():
            if line.startswith("GRUB_THEME="):
                path = line.split("=", 1)[1].strip().strip('"')
                if path:
                    theme_dir = Path(path).parent
                    return theme_dir.name if theme_dir.name else "-"
    except (OSError, PermissionError):
        pass
    return "-"


def get_installed_themes() -> list[str]:
    """Return sorted list of installed theme names."""
    themes_dir = get_grub_themes_dir()
    if not themes_dir:
        return []
    themes = []
    try:
        for p in themes_dir.iterdir():
            if p.is_dir() and (p / "theme.txt").is_file():
                themes.append(p.name)
    except (OSError, PermissionError):
        pass
    return sorted(themes)


def get_status() -> dict:
    """Return a dict with current theme, count, and installed list."""
    installed = get_installed_themes()
    return {
        "current": get_current_theme(),
        "count": len(installed),
        "installed": installed,
    }


def _run_grub_script(*args: str) -> tuple[int, str, str]:
    """Run the GRUB bash script with given args and return (rc, stdout, stderr)."""
    script = SCRIPTS_DIR / "grub.sh"
    if not script.is_file():
        return 1, "", f"Script not found: {script}"
    result = subprocess.run(
        ["bash", str(script), *args],
        capture_output=True,
        text=True,
        timeout=300,
    )
    return result.returncode, result.stdout, result.stderr


def install_theme(theme_name: str) -> str:
    """Install a GRUB theme by name. Returns output string."""
    rc, out, err = _run_grub_script("--install", theme_name)
    if rc != 0:
        return f"Failed: {err or out}"
    return out.strip() or f"Theme '{theme_name}' installation completed."


def apply_theme(theme_name: str) -> str:
    """Apply an already-installed theme by name."""
    themes_dir = get_grub_themes_dir()
    if not themes_dir:
        return "No GRUB themes directory found."
    theme_path = themes_dir / theme_name / "theme.txt"
    if not theme_path.is_file():
        return f"Theme '{theme_name}' not found at {theme_path}"

    try:
        config_text = GRUB_CONFIG.read_text()
        config_text = re.sub(
            r"^GRUB_THEME=.*\n?", "", config_text, flags=re.MULTILINE
        )
        config_text += f'\nGRUB_THEME="{theme_path}"\n'
        subprocess.run(
            ["sudo", "tee", str(GRUB_CONFIG)], input=config_text,
            text=True, capture_output=True, check=True,
        )

        # Ensure GRUB_TIMEOUT_STYLE=menu
        if "GRUB_TIMEOUT_STYLE=menu" not in config_text:
            config_text = re.sub(
                r"^GRUB_TIMEOUT_STYLE=.*\n?", "", config_text, flags=re.MULTILINE
            )
            config_text += "\nGRUB_TIMEOUT_STYLE=menu\n"
            subprocess.run(
                ["sudo", "tee", str(GRUB_CONFIG)], input=config_text,
                text=True, capture_output=True, check=True,
            )

        prefix = _get_grub_prefix()
        result = subprocess.run(
            ["sudo", GRUB_BINARY, "-o", f"/boot/{prefix}/grub.cfg"],
            capture_output=True, text=True, timeout=60,
        )
        if result.returncode != 0:
            return f"GRUB update failed: {result.stderr}"
        return f"Theme '{theme_name}' applied successfully!"
    except subprocess.CalledProcessError as e:
        return f"Failed: {e.stderr or e.stdout}"
    except (OSError, PermissionError) as e:
        return f"Permission error: {e}"


def remove_theme(theme_name: str) -> str:
    """Remove a theme by name from the themes directory."""
    themes_dir = get_grub_themes_dir()
    if not themes_dir:
        return "No GRUB themes directory found."
    target = themes_dir / theme_name
    if not target.is_dir():
        return f"Theme '{theme_name}' not found."

    try:
        shutil.rmtree(str(target))
        return f"Theme '{theme_name}' removed."
    except (OSError, PermissionError) as e:
        return f"Failed to remove: {e}"


def list_themes() -> str:
    """Return formatted list of all available themes from the bash script."""
    rc, out, err = _run_grub_script("--list")
    if rc != 0:
        return f"Failed to list themes: {err or out}"
    return out


def search_themes(query: str) -> str:
    """Search themes by keyword. Returns formatted results."""
    rc, out, err = _run_grub_script("--search", query)
    if rc != 0:
        return f"Search failed: {err or out}"
    return out


def reboot() -> str:
    """Reboot the system."""
    try:
        subprocess.run(["sudo", "reboot"], check=True)
    except subprocess.CalledProcessError:
        pass
    return "Reboot initiated."


def set_resolution(resolution: str) -> str:
    """Set GRUB GFXMODE."""
    try:
        config_text = GRUB_CONFIG.read_text()
        config_text = re.sub(
            r"^GRUB_GFXMODE=.*\n?", "", config_text, flags=re.MULTILINE
        )
        config_text += f"GRUB_GFXMODE={resolution}\n"
        subprocess.run(
            ["sudo", "tee", str(GRUB_CONFIG)], input=config_text,
            text=True, capture_output=True, check=True,
        )
        prefix = _get_grub_prefix()
        result = subprocess.run(
            ["sudo", GRUB_BINARY, "-o", f"/boot/{prefix}/grub.cfg"],
            capture_output=True, text=True, timeout=60,
        )
        if result.returncode != 0:
            return f"GRUB update failed: {result.stderr}"
        return f"Resolution set to {resolution}"
    except (OSError, PermissionError) as e:
        return f"Failed: {e}"


def reset_default() -> str:
    """Reset GRUB theme to default (no custom theme)."""
    try:
        config_text = GRUB_CONFIG.read_text()
        config_text = re.sub(
            r"^GRUB_THEME=.*\n?", "", config_text, flags=re.MULTILINE
        )
        subprocess.run(
            ["sudo", "tee", str(GRUB_CONFIG)], input=config_text,
            text=True, capture_output=True, check=True,
        )
        subprocess.run(
            ["sudo", "grub-editenv", "-", "unset", "theme"],
            capture_output=True, timeout=10,
        )
        prefix = _get_grub_prefix()
        result = subprocess.run(
            ["sudo", GRUB_BINARY, "-o", f"/boot/{prefix}/grub.cfg"],
            capture_output=True, text=True, timeout=60,
        )
        if result.returncode != 0:
            return f"GRUB update failed: {result.stderr}"
        return "Reset to default GRUB theme."
    except (OSError, PermissionError) as e:
        return f"Failed: {e}"
