"""Neovim / LazyVim Setup Module.

Calls the existing neovim setup script from the dotfiles repo.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def setup_neovim() -> str:
    """Install Neovim with Lazy plugin manager and basic config."""
    setup_script = DOTFILES_DIR / "scripts/setup/neovim.sh"
    if not setup_script.is_file():
        return f"Neovim setup script not found: {setup_script}"

    result = subprocess.run(
        [
            "bash", "-c",
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{DOTFILES_DIR}/scripts/pkg/manager.sh" && '
            f'source "{setup_script}" && setup_neovim',
        ],
        capture_output=True, text=True, timeout=300,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"Neovim setup failed: {err or out}"
    return out or "Neovim setup completed."
