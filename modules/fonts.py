"""Font Installation Module.

Calls the existing fonts setup script from the dotfiles repo.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def install_fonts() -> str:
    """Install Meslo Nerd Font and JetBrains Mono via the existing setup script."""
    setup_script = DOTFILES_DIR / "scripts/setup/fonts.sh"
    if not setup_script.is_file():
        return f"Fonts setup script not found: {setup_script}"

    # Source + call the setup_fonts function within the dotfiles environment
    result = subprocess.run(
        [
            "bash", "-c",
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{setup_script}" && setup_fonts',
        ],
        capture_output=True, text=True, timeout=120,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"Font installation failed: {err or out}"
    return out or "Fonts installed successfully."
