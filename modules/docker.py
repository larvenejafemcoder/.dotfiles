"""Docker Installation Module.

Wraps the existing docker setup script from the dotfiles repo.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def setup_docker() -> str:
    """Install Docker and Docker Compose via the existing setup script."""
    setup_script = DOTFILES_DIR / "scripts/setup/docker.sh"
    if not setup_script.is_file():
        return f"Docker setup script not found: {setup_script}"

    result = subprocess.run(
        [
            "bash", "-c",
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{DOTFILES_DIR}/scripts/pkg/manager.sh" && '
            f'source "{setup_script}" && setup_docker',
        ],
        capture_output=True, text=True, timeout=180,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"Docker setup failed: {err or out}"
    return out or "Docker installed successfully."
