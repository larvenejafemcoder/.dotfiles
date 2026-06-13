"""Theme Installation Module.

Wraps the existing themes setup script from the dotfiles repo.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def _run_themes_fn(fn_name: str) -> str:
    """Run a specific theme setup function from the bash script."""
    setup_script = DOTFILES_DIR / "scripts/setup/themes.sh"
    if not setup_script.is_file():
        return f"Themes setup script not found: {setup_script}"

    result = subprocess.run(
        [
            "bash", "-c",
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{DOTFILES_DIR}/scripts/pkg/manager.sh" && '
            f'source "{setup_script}" && {fn_name}',
        ],
        capture_output=True, text=True, timeout=300,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"{fn_name} failed: {err or out}"
    return out or f"{fn_name} completed."


def setup_catppuccin() -> str:
    """Install Catppuccin GTK theme and icons."""
    return _run_themes_fn("setup_catppuccin")


def setup_gnome_themes() -> str:
    """Install GNOME themes (Tahoe, WhiteSur)."""
    return _run_themes_fn("setup_gnome_themes")


def setup_themes() -> str:
    """Install all themes (Catppuccin + GNOME)."""
    return _run_themes_fn("setup_themes")
