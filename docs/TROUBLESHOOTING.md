# Troubleshooting

> **Documentation version:** 2.0.0

---

## Error Matrix

| Error message | Cause | Solution | Related command |
|--------------|-------|----------|-----------------|
| `tui_init: command not found` | `tui_init()` failed silently | Check dependencies | `bash -x install.sh --setup` |
| `dialog: command not found` | Dialog not installed | `sudo apt install dialog` or `sudo pacman -S dialog` | `apt install dialog` |
| `Whiptail error: whiptail: not found` | Neither dialog nor whiptail | Install one of them | `apt install whiptail` |
| `SETUP_MODE=true: unbound variable` | `set -u` — variable used before declaration | Check variable initialization order | Ensure all vars declared before functions |
| `Permission denied on /usr/local/go` | No sudo session | Run `sudo -v` first or re-run with cached sudo | `sudo -v` |
| `Symlink failed: File exists` | Existing regular file blocks symlink | `backup_dotfile()` should handle this — check backups in `$SETUP_BACKUP_DIR` | `ls -la $SETUP_BACKUP_DIR/` |
| `Dotfiles repo not found` | `DOTFILES_DIR` is wrong | Ensure you're running from the repo root | `ls $DOTFILES_DIR/install.sh` |
| `Could not detect package manager` | Unknown distro | Check `detect_package_manager()` in `scripts/pkg/manager.sh`; add your distro | `echo $DISTRO` |
| `Offline — skipping: ...` | `--offline` flag is set, or no network | Remove `--offline` or connect to network | Check `ping google.com` |
| `curl: (6) Could not resolve host` | No network | Either fix network or use `--offline` | `ping google.com` |
| `tee: ...: No such file or directory` | Log directory doesn't exist | `interactive_setup()` should create it; check permissions | `mkdir -p ~/.config/dotfiles-setup` |
| `Already linked` messages but file doesn't exist | Symlink was deleted; script thinks it exists | Re-run to recreate | `./install.sh --dotfiles-only` |

---

## Interactive Mode Issues

### TUI doesn't start

```
Warning: neither dialog nor whiptail found.
```

Install one:

```bash
# Debian/Ubuntu
sudo apt install dialog

# Arch
sudo pacman -S dialog

# Fedora
sudo dnf install dialog
```

### TUI shows blank screen or garbage

The terminal might not support ncurses properly:

```bash
# Reset terminal
reset

# Check TERM variable
echo $TERM    # should be xterm-256color or similar

# Try with explicit terminal type
TERM=xterm-256color ./install.sh --setup
```

### Checklist returns empty (no selections)

The user likely pressed Cancel. This is by design — `|| return` exits the
function gracefully.

---

## Automated Mode Issues

### Installation hangs

If the script appears to hang, check:

1. **Package manager lock** — another `apt`/`pacman` process is running:
   ```bash
   sudo rm /var/lib/dpkg/lock-frontend   # Debian/Ubuntu (use with caution)
   ```

2. **Sudo prompt blocking** — the script is waiting for sudo:
   ```bash
   sudo -v   # Pre-authenticate
   ```

3. **Network timeout** — a `curl` command is retrying:
   ```bash
   # Use OFFLINE
   ./install.sh --unattended --offline
   ```

### Package installation fails mid-way

```bash
# Check the log
less ~/.config/dotfiles-setup/install-latest.log

# Look for ERROR lines
grep ERROR ~/.config/dotfiles-setup/install-*.log
```

Common fixes:

| Package | Issue | Fix |
|---------|-------|-----|
| neovim | PPA not available | `apt-add-repository` failed; install via `pacman`/`dnf` instead |
| docker | get.docker.com unreachable | Use distro package: `apt install docker.io` |
| nvm | curl failed | Manual install: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash` |

---

## Dotfile Management

### A dotfile wasn't symlinked

1. Check if the source exists:
   ```bash
   ./install.sh --debug --dotfiles-only
   ```

2. Manually test `dotfile_source()`:
   ```bash
   source install.sh
   dotfile_source ".zshrc"   # Should print path
   ```

3. The file might not match any search path. Add it to a stow package or a
   known directory.

### Stow fails with "existing file is not owned by stow"

A previous manual install left a regular file:

```bash
# Remove the conflicting file (backed up first!)
rm ~/.config/alacritty/alacritty.yml

# Re-run stow
(cd stow && stow -R alacritty)
```

### Backup directory is huge

Old backups accumulate. Clean up:

```bash
# Remove all backups older than 30 days
find ~/.config/dotfiles-setup/backups/ -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +

# Or just nuke them all
rm -rf ~/.config/dotfiles-setup/backups/*
```

---

## Recovery Procedures

### Restore a single dotfile from backup

```bash
# Find the backup
ls ~/.config/dotfiles-setup/backups/*/home/*/.zshrc

# Restore
cp ~/.config/dotfiles-setup/backups/20260613-143022/home/user/.zshrc ~/.zshrc
```

### Roll back all symlinks

```bash
./install.sh --rollback
```

This restores from `~/.backup-YYYY-MM-DD/` (created by `scripts/dotfiles/deploy.sh`).

### Force clean reinstall

```bash
# 1. Remove all symlinks created by the script
find ~/.config/dotfiles-setup/backups/latest/ -type f | while read f; do
    target="${f#*home/*/}"
    [ -L "$HOME/$target" ] && rm "$HOME/$target"
done

# 2. Remove config directory
rm -rf ~/.config/dotfiles-setup

# 3. Re-run from scratch
./install.sh --setup
```

---

## Log Locations

| Log | Path | Contains |
|-----|------|----------|
| Interactive session | `~/.config/dotfiles-setup/install-*.log` | All operations |
| Latest interactive | `~/.config/dotfiles-setup/install-latest.log` | Symlink to most recent |
| Automated install | `$LOG_FILE` (set by `scripts/core/logging.sh`) | Usually under `/tmp/` |
| History | `~/.config/dotfiles-setup/history.log` | Summary of each run |
| Backup record | `~/.config/dotfiles-setup/backups/*/` | Pre-overwrite files |

```bash
# View the last interactive run
less ~/.config/dotfiles-setup/install-latest.log

# Search for errors across all logs
grep -r "ERROR\|FAILED\|Failed" ~/.config/dotfiles-setup/
```

---

## Debug Checklist

If something isn't working, run through these steps:

```bash
# 1. Syntax check
bash -n install.sh

# 2. Dry run with debug
bash -x install.sh --dry-run 2>&1 | less

# 3. Check dependencies
which bash dialog whiptail git curl stow

# 4. Check log
cat ~/.config/dotfiles-setup/install-latest.log

# 5. Check backups
ls -la ~/.config/dotfiles-setup/backups/

# 6. Reproduce with debug
bash -x install.sh --setup 2>&1 | tee /tmp/debug.log
```

---

## Reporting Issues

When reporting a bug, include:

1. Output of `bash --version`
2. Output of `cat /etc/os-release`
3. The full command you ran
4. The output (including error messages)
5. The log file: `~/.config/dotfiles-setup/install-latest.log`
6. Whether dialog/whiptail are installed: `which dialog whiptail`

---

## Quick Reference

```bash
# Fix sudo timeout
sudo -v

# Reset terminal
reset

# Check log in real-time
tail -f ~/.config/dotfiles-setup/install-latest.log

# Re-run last interactive session
./install.sh --repeat

# Skip all network operations
./install.sh --setup --offline

# Run verbosely
bash -x install.sh --debug --dotfiles-only 2>&1 | less
```
