# Glossary

> **Documentation version:** 2.0.0

---

| Term | Definition |
|------|------------|
| **ANSI escape code** | Terminal control sequences starting with `\033[` that control text color, style, and cursor position. |
| **Backup** | A timestamped copy of a user file created before overwriting. Stored in `$SETUP_BACKUP_DIR`. |
| **Bare repository** | A Git repository without a working tree, often used with `--work-tree=$HOME` for dotfile management (not used here). |
| **Checklist** | A TUI widget showing multiple toggleable items (dialog/whiptail `--checklist`). |
| **DE** | Desktop Environment — e.g., GNOME, KDE, XFCE. |
| **Dialog** | A TUI program for dialog boxes — preferred backend (richer UI than whiptail). |
| **Dotfile** | A configuration file or directory starting with `.` (dot) in `$HOME`, e.g., `.zshrc`, `.config/nvim/`. |
| **Dotfiles** | (Plural) A collection of user configuration files managed as a set. |
| **GNU Stow** | A symlink manager. Installed packages in `stow/` are symlinked to `$HOME` with `stow -R`. |
| **Idempotent** | An operation that produces the same result no matter how many times it's run. Safe to re-run. |
| **INI file** | A simple configuration format with `[section]` headers and `key=value` pairs. |
| **Menu** | A TUI widget showing a selectable list (dialog/whiptail `--menu`). |
| **Msgbox** | A TUI widget showing a message with an OK button (dialog/whiptail `--msgbox`). |
| **nvm** | Node Version Manager — manages multiple Node.js installations in `~/.nvm`. |
| **Pipeline** | A sequence of commands connected by `\|`, where each command's stdout feeds the next's stdin. |
| **PPA** | Personal Package Archive — Ubuntu/Debian repository hosted on Launchpad. |
| **Profile** | A named desktop configuration (hyprland, i3, default) passed to `setup_desktop()`. |
| **Rollback** | The process of undoing a deployment, restoring previous symlinks from a backup. |
| **rustup** | The Rust toolchain installer — manages `rustc`, `cargo`, and related tools. |
| **set -e** | Bash option: exit immediately if a command returns non-zero. |
| **set -u** | Bash option: treat unset variables as an error. |
| **set -o pipefail** | Bash option: a pipeline fails if any stage fails, not just the last. |
| **Shebang** | The first line of a script (`#!/usr/bin/env bash`) that tells the kernel which interpreter to use. |
| **Stow** | See GNU Stow. |
| **Symlink** | Symbolic link — a special file that points to another file or directory. |
| **TUI** | Textual User Interface — terminal-based interactive UI (dialog, whiptail, Textual). |
| **Textual** | A Python TUI framework for building rich terminal applications. |
| **Whiptail** | A lightweight TUI program similar to dialog, often pre-installed on minimal systems. |
| **WM** | Window Manager — e.g., Hyprland, i3, Sway, Openbox. |
| **XDG Base Directory** | A specification for where user files go: `$XDG_CONFIG_HOME` (default `~/.config`), `$XDG_CACHE_HOME` (default `~/.cache`), `$XDG_DATA_HOME` (default `~/.local/share`). |
| **Yesno** | A TUI widget showing a Yes/No prompt (dialog/whiptail `--yesno`). |
