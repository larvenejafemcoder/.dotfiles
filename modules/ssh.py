"""SSH and GPG Key Generation Module.

Wraps the existing SSH setup script from the dotfiles repo.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def setup_ssh_keys() -> str:
    """Generate SSH and GPG keys via the existing setup script."""
    setup_script = DOTFILES_DIR / "scripts/setup/ssh.sh"
    if not setup_script.is_file():
        return f"SSH setup script not found: {setup_script}"

    result = subprocess.run(
        [
            "bash", "-c",
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{DOTFILES_DIR}/scripts/pkg/manager.sh" && '
            f'source "{setup_script}" && setup_ssh_keys',
        ],
        capture_output=True, text=True, timeout=120,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"SSH key setup failed: {err or out}"
    return out or "SSH keys generated successfully."
