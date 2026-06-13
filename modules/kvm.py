"""KVM/QEMU Virtualization Module.

Wraps the existing KVM setup script from the dotfiles repo.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def setup_kvm() -> str:
    """Install KVM/QEMU/libvirt via the existing setup script."""
    setup_script = DOTFILES_DIR / "scripts/setup/kvm.sh"
    if not setup_script.is_file():
        return f"KVM setup script not found: {setup_script}"

    result = subprocess.run(
        [
            "bash", "-c",
            f'source "{DOTFILES_DIR}/scripts/core/colors.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/logging.sh" && '
            f'source "{DOTFILES_DIR}/scripts/core/utils.sh" && '
            f'source "{DOTFILES_DIR}/scripts/pkg/manager.sh" && '
            f'source "{setup_script}" && setup_kvm',
        ],
        capture_output=True, text=True, timeout=180,
    )
    out = (result.stdout or "").strip()
    err = (result.stderr or "").strip()
    if result.returncode != 0:
        return f"KVM setup failed: {err or out}"
    return out or "KVM/QEMU configured successfully."
