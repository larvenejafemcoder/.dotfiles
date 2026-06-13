"""Development Tools Module.

Wraps the existing dev setup script from the dotfiles repo
for Git, Node, Rust, Go, and Python configuration.
"""

import subprocess
from pathlib import Path

from . import DOTFILES_DIR


def _run_dev_fn(fn_name: str) -> str:
    """Run a specific dev setup function from the bash script."""
    setup_script = DOTFILES_DIR / "scripts/setup/dev.sh"
    if not setup_script.is_file():
        return f"Dev setup script not found: {setup_script}"

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


def setup_git() -> str:
    """Configure Git with global settings."""
    return _run_dev_fn("setup_git")


def setup_node() -> str:
    """Install Node.js via nvm/fnm or system package manager."""
    return _run_dev_fn("setup_node")


def setup_rust() -> str:
    """Install Rust via rustup."""
    return _run_dev_fn("setup_rust")


def setup_go() -> str:
    """Install Go."""
    return _run_dev_fn("setup_go")


def setup_python() -> str:
    """Configure Python tooling (pip, pipx)."""
    return _run_dev_fn("setup_python")


def setup_development() -> str:
    """Install all development tools (Git, Node, Rust, Go, Python)."""
    return _run_dev_fn("setup_development")
