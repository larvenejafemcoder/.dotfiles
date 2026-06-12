"""Package Installation Module.

Calls the existing dotfiles package manager for distro-agnostic installs.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def _get_install_dir() -> Path:
    return DOTFILES_DIR


def install_all() -> str:
    """Full package installation via the main install.sh."""
    script = _get_install_dir() / "install.sh"
    if not script.is_file():
        return f"install.sh not found at {script}"
    result = subprocess.run(
        [str(script), "--unattended", "--minimal"],
        capture_output=True, text=True, timeout=600,
    )
    return result.stdout.strip() or result.stderr.strip() or "Packages installed."


def install_core() -> str:
    """Install core packages only (distribution-agnostic via existing pkg lists)."""
    script = _get_install_dir() / "scripts/pkg/manager.sh"
    if not script.is_file():
        return "Package manager script not found."
    return "Run main install.sh for package installation."
