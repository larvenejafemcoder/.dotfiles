#!/usr/bin/env python3
"""Installer dispatch backend - maps component names to module installer functions."""

import subprocess
from pathlib import Path
from typing import Dict, Optional

from modules import DOTFILES_DIR
from modules.shell import setup_zsh, setup_starship
from modules.lazyvim import setup_neovim
from modules.docker import setup_docker
from modules.kvm import setup_kvm
from modules.desktop import setup_hyprland, setup_i3
from modules.themes import setup_catppuccin, setup_themes
from modules.brave import setup_brave
from modules.ssh import setup_ssh_keys
from modules.dev import setup_git, setup_node, setup_rust, setup_go, setup_python
from modules.fonts import install_fonts
from modules.packages import install_all, install_core


INSTALLER_MAP: Dict[str, str] = {
    "zsh": "shell::setup_zsh",
    "oh_my_zsh": "shell::setup_zsh",
    "powerlevel10k": "shell::setup_zsh",
    "starship": "shell::setup_starship",
    "nvim_lazy": "lazyvim::setup_neovim",
    "nvim_nvchad": "lazyvim::setup_neovim",
    "nvim_astro": "lazyvim::setup_neovim",
    "nvim_basic": "lazyvim::setup_neovim",
    "docker": "docker::setup_docker",
    "docker_compose": "docker::setup_docker",
    "kvm": "kvm::setup_kvm",
    "hyprland": "desktop::setup_hyprland",
    "i3wm": "desktop::setup_i3",
    "bspwm": "desktop::setup_i3",
    "git_enhanced": "dev::setup_git",
    "git_aliases": "dev::setup_git",
    "git_ignore_global": "dev::setup_git",
    "nodejs_dev": "dev::setup_node",
    "rust_dev": "dev::setup_rust",
    "go_dev": "dev::setup_go",
    "python_dev": "dev::setup_python",
    "catppuccin": "themes::setup_catppuccin",
    "themes": "themes::setup_themes",
    "brave": "brave::setup_brave",
    "ssh": "ssh::setup_ssh_keys",
    "fonts": "fonts::install_fonts",
    "everything": "packages::install_all",
    "minimal": "packages::install_core",
}

FUNC_MAP = {
    "shell::setup_zsh": setup_zsh,
    "shell::setup_starship": setup_starship,
    "lazyvim::setup_neovim": setup_neovim,
    "docker::setup_docker": setup_docker,
    "kvm::setup_kvm": setup_kvm,
    "desktop::setup_hyprland": setup_hyprland,
    "desktop::setup_i3": setup_i3,
    "themes::setup_catppuccin": setup_catppuccin,
    "themes::setup_themes": setup_themes,
    "brave::setup_brave": setup_brave,
    "ssh::setup_ssh_keys": setup_ssh_keys,
    "dev::setup_git": setup_git,
    "dev::setup_node": setup_node,
    "dev::setup_rust": setup_rust,
    "dev::setup_go": setup_go,
    "dev::setup_python": setup_python,
    "fonts::install_fonts": install_fonts,
    "packages::install_all": install_all,
    "packages::install_core": install_core,
}


async def install_component(name: str) -> tuple[bool, str]:
    """Install a single component by name. Returns (success, log_message)."""
    try:
        if name in INSTALLER_MAP:
            mapping = INSTALLER_MAP[name]
            fn = FUNC_MAP[mapping]
            result = fn()
            log_line = str(result)[:120] if result else "OK"
            return True, log_line

        install_sh = Path(DOTFILES_DIR / "install.sh")
        if install_sh.is_file():
            result = subprocess.run(
                [str(install_sh), "--unattended", "--minimal", f"--only={name}"],
                capture_output=True, text=True, timeout=600,
            )
            return result.returncode == 0, result.stdout[:120] or "OK"

        return False, f"No installer found for {name}"
    except Exception as e:
        return False, str(e)
