"""Shell Setup Module (Zsh, Starship, Fish).

Calls the existing shell setup script from the dotfiles repo.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def setup_zsh() -> str:
    """Install Oh My Zsh, Powerlevel10k, and plugins."""
    setup_script = DOTFILES_DIR / "scripts/setup/shell.sh"
    if not setup_script.is_file():
        return f"Shell setup script not found: {setup_script}"

    result = subprocess.run(
        [
            "bash", "-c",
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{DOTFILES_DIR}/scripts/pkg/manager.sh" && '
            f'source "{setup_script}" && setup_zsh',
        ],
        capture_output=True, text=True, timeout=180,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"Zsh setup failed: {err or out}"
    return out or "Zsh setup completed."


def setup_starship() -> str:
    """Install Starship prompt."""
    setup_script = DOTFILES_DIR / "scripts/setup/shell.sh"
    result = subprocess.run(
        [
            "bash", "-c",
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{DOTFILES_DIR}/scripts/pkg/manager.sh" && '
            f'source "{setup_script}" && setup_starship',
        ],
        capture_output=True, text=True, timeout=120,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"Starship setup failed: {err or out}"
    return out or "Starship installed."
