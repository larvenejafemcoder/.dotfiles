# Frequently Asked Questions

> **Documentation version:** 2.0.0

---

### Q1: What does this script do?

It's a dotfiles manager and dev-environment installer. You can use it
interactively (checklist-style) to choose which dotfiles to symlink and which
dev tools to install, or in fully automated mode for a headless setup.

### Q2: Will it overwrite my existing dotfiles?

Existing files are **backed up** before being replaced. Backups go to
`~/.config/dotfiles-setup/backups/YYYYMMDD-HHMMSS/`. If the target is already
a symlink pointing to the correct source, it's skipped entirely (no backup
needed).

### Q3: Which Linux distros are supported?

Arch, Ubuntu/Debian, Fedora, and openSUSE. Partial support for macOS (package
manager detection may fall through to `apt`).

### Q4: I don't have dialog or whiptail. Can I still use the script?

Yes — use `--unattended` for a fully automated non-interactive install, or
`--tui` for the Textual Python TUI (requires Python 3.10+). The interactive
flags (`--setup`, `--dotfiles-only`, `--tools-only`) require either dialog or
whiptail.

### Q5: How do I re-run with the same selections?

```bash
./install.sh --repeat
```

This reads `~/.config/dotfiles-setup/selections.cfg` and re-applies the saved
choices. Currently reserved for future implementation — for now, re-run with
the same flags.

### Q6: Can I use this without internet?

```bash
./install.sh --setup --offline
```

Symlinks work without network. Package installs and tool downloads are skipped
with `WARN Offline — skipping` messages.

### Q7: How do I install only dotfiles (no tools)?

```bash
./install.sh --dotfiles-only
```

### Q8: How do I install only tools (no dotfiles)?

```bash
./install.sh --tools-only
```

### Q9: The TUI shows garbled characters. What's wrong?

Your terminal may not support UTF-8 or has a wrong `$TERM` setting:

```bash
export TERM=xterm-256color
./install.sh --setup
```

If using `dialog`, try `export NCURSES_NO_UTF8_ACS=1` to force ASCII line
drawing.

### Q10: Installation failed halfway through. What now?

1. Check the log: `less ~/.config/dotfiles-setup/install-latest.log`
2. Search for errors: `grep ERROR ~/.config/dotfiles-setup/install-*.log`
3. Fix the issue (network, permissions, missing dependency)
4. Re-run — the script is idempotent; already-completed steps are skipped

### Q11: How do I uninstall / rollback?

```bash
./install.sh --rollback
```

This restores symlinks from `~/.backup-YYYY-MM-DD/` (created by the deploy
script during `--unattended` mode). For interactive backups, manually restore
from `~/.config/dotfiles-setup/backups/`.

### Q12: The script says "sudo needed" too often. Can I cache it longer?

Increase the sudo timeout:

```bash
sudo visudo -f /etc/sudoers.d/timestamp
# Add: Defaults timestamp_timeout=30  # 30 minutes
```

### Q13: What if my package manager is not detected?

The script tries to auto-detect your distro via `/etc/os-release`. If that
fails, it defaults to `apt` as a fallback. You can override:

```bash
PKG_MANAGER=pacman ./install.sh --unattended
```

### Q14: I use fish, not zsh. Can I still use this?

Yes — the script treats shells as independent dotfiles. Select `.config/fish`
from the dotfiles checklist and deselect `.zshrc`. The shell setup step is
guarded by `INSTALL_ZSH` (disable with `--no-zsh`).

### Q15: How do I add my own dotfile or tool?

See the [Development Guide](DEVELOPMENT.md). For dotfiles: add an entry to
`DOTFILES_ITEMS` and place the source file in `stow/` or another searched
directory. For tools: follow the `install_*_interactive()` pattern and add a
case entry in `interactive_tools()`.

### Q16: Can I use this on NixOS?

Not directly — NixOS uses a completely different package model. The dotfile
symlinking (`install_dotfile()`) would work for config files managed outside
the Nix store, but package installation would fail.

### Q17: Does it work on Termux (Android)?

There's a `bootstrap-termux.sh` script in `assets/scripts/` with partial
support. `install.sh` itself is not tested on Termux.

### Q18: What's the difference between `install.sh`, `setup.sh`, and `tui.sh`?

| Script | Purpose | Interface |
|--------|---------|-----------|
| `install.sh` | Main entry point (this script) | CLI + dialog/whiptail TUI |
| `setup.sh` | Standalone interactive script (deprecated) | dialog/whiptail TUI |
| `tui.sh` | Python TUI bootstrap | Textual (Python) TUI |

Use `install.sh` for everything. `setup.sh` is kept for backward compatibility.
`tui.sh` provides an alternative rich TUI.

### Q19: How do I see what changed after running?

```bash
# Dotfile changes: check the backup diff
diff ~/.config/dotfiles-setup/backups/20260613-143022/home/user/.zshrc ~/.zshrc

# Installed packages: check the log
grep "Installed\|OK" ~/.config/dotfiles-setup/install-latest.log

# Symlinks created:
find ~/.config/dotfiles-setup/backups/20260613-143022/ -type f | while read f; do
    target="${f#*home/*/}"
    [ -L "$HOME/$target" ] && echo "Linked: $target"
done
```

### Q20: Can I run this as a non-root user?

**Yes** — the script never asks for full root context. Only specific commands
use `sudo` (package installs, system-wide tool installation). Dotfile
symlinks, TUI interaction, and logging all run as your user.
