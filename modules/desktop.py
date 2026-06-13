"""Desktop Environment Module.

Wraps the existing desktop setup script from the dotfiles repo.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def _run_desktop_fn(fn_name: str) -> str:
    """Run a specific desktop setup function from the bash script."""
    setup_script = DOTFILES_DIR / "scripts/setup/desktop.sh"
    if not setup_script.is_file():
        return f"Desktop setup script not found: {setup_script}"

    result = subprocess.run(
        [
            "bash", "-c",
            f'export DESKTOP_PROFILE="${{DESKTOP_PROFILE:-default}}" && '
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


def setup_hyprland() -> str:
    """Install Hyprland desktop environment."""
    return _run_desktop_fn("setup_hyprland")


def setup_i3() -> str:
    """Install i3 desktop environment."""
    return _run_desktop_fn("setup_i3")


def setup_desktop(profile: str = "default") -> str:
    """Install desktop environment based on profile (hyprland, i3, default)."""
    result = subprocess.run(
        [
            "bash", "-c",
            f'export DESKTOP_PROFILE="{profile}" && '
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{DOTFILES_DIR}/scripts/pkg/manager.sh" && '
            f'source "{DOTFILES_DIR}/scripts/setup/desktop.sh" && setup_desktop',
        ],
        capture_output=True, text=True, timeout=300,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"Desktop setup failed: {err or out}"
    return out or f"Desktop profile '{profile}' configured."
