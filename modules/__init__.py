"""TUI Modules - wrappers for dotfiles setup scripts."""

from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = BASE_DIR / "scripts"
DOTFILES_DIR = BASE_DIR
