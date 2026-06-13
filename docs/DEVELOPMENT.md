# Development Guide

> **Documentation version:** 2.0.0

---

## Repository Structure

```
dotfiles/
├── install.sh              # Main entry point
├── tui.sh                  # Python TUI bootstrap
├── main.py                 # Textual TUI application
├── modules/                # Python TUI screens
├── scripts/
│   ├── core/               # Bash library files
│   │   ├── colors.sh       # ANSI color variables
│   │   ├── detect.sh       # OS/distro/DE detection
│   │   ├── logging.sh      # Logging framework
│   │   ├── ui.sh           # Boot screen, dashboard
│   │   └── utils.sh        # Miscellaneous helpers
│   ├── pkg/manager.sh      # Package manager abstraction
│   ├── dotfiles/deploy.sh  # Stow + backup logic
│   ├── setup/              # Component installers
│   └── verify/verify.sh    # Post-install checks
├── config/packages/        # Per-distro package lists
├── stow/                   # GNU Stow-managed dotfiles
├── bootstrap*.sh           # Legacy bootstrappers
└── setup.sh                # Deprecated standalone script
```

---

## Coding Standards

### Shell Scripts

- **Shebang:** Always `#!/usr/bin/env bash`
- **Safety:** `set -euo pipefail` at the top of every script
- **Naming:**
  - Uppercase with underscores for exported globals: `DOTFILES_DIR`, `PKG_MANAGER`
  - Lowercase for function-local variables: `local name="$1"`, `local count=0`
  - Prefix interactive functions with `setup_` (`setup_ok`, `setup_run`)
  - Prefix TUI wrappers with `tui_` (`tui_menu`, `tui_checklist`)
- **Quoting:** Always double-quote variable expansions: `"$@"` not `$@`, `"$file"` not `$file`
- **Error handling:** Use `|| true` to allow expected failures; prefer `if cmd; then` over `cmd; rc=$?`
- **Line length:** Max 100 characters
- **Indentation:** 4 spaces (no tabs)

### Validation

```bash
# Syntax check
bash -n install.sh

# ShellCheck (install via your package manager)
shellcheck install.sh

# Look for common issues
bash -x install.sh --dry-run
```

> [!IMPORTANT]
> Run `bash -n install.sh` after every edit. The `set -euo pipefail` regime
> catches many errors at runtime, but `bash -n` catches syntax errors before
> execution.

---

## Adding a New Tool

### Step 1: Create the installer function

Add to `install.sh` following the existing pattern:

```bash
install_mytool_interactive() {
    command -v mytool &>/dev/null && {
        setup_log "  ${cD}✓ mytool already installed${cN}"
        echo "  ✓ mytool" >> "$SETUP_SUMMARY"
        return 0
    }
    [ "$OFFLINE" = 1 ] && {
        echo "  - mytool (offline)" >> "$SETUP_SUMMARY"
        return 0
    }
    setup_run "Installing mytool..." bash -c "curl -fsSL https://get.mytool.dev | sh"
    echo "  ✓ mytool" >> "$SETUP_SUMMARY"
}
```

### Step 2: Add to the tools checklist in `interactive_tools()`

```bash
tools_sel=$(tui_checklist "Dev Tools" ... \
    ...
    "─── My Category ───" "" OFF \
    "mytool"   "Description of mytool" OFF \
    ...
)
```

### Step 3: Add to the dispatch case statement

```bash
for tool in $tools_sel; do
    case "$tool" in
        ...
        mytool) install_mytool_interactive;;
        ...
    esac
done
```

### Step 4: (Optional) Add automated install support

If the tool should also be installed during `--unattended` mode, add it to the
appropriate `scripts/setup/*.sh` file and create a `setup_mytool()` function.

---

## Adding a New Dotfile

### Step 1: Add to `DOTFILES_ITEMS`

```bash
DOTFILES_ITEMS=(
    ...
    ".config/myapp/config.yml" "MyApp configuration" off
)
```

### Step 2: Place the source file

Put it in one of the locations searched by `dotfile_source()`:

- `stow/<pkg>/` (preferred for stow-managed packages)
- `$DOTFILES_DIR/` (repo root)
- `$DOTFILES_DIR/home/`
- `$DOTFILES_DIR/config/`
- `$DOTFILES_DIR/shell/`, `git/`, `tmux/`, `terminal/`

### Step 3: (Optional) Stow package

If using stow:

```bash
mkdir -p stow/myapp/.config/myapp
cp myconfig.yml stow/myapp/.config/myapp/config.yml
```

The dotfile will then match automatically in `dotfile_source()` because the
stow package name matches the second path component.

---

## Testing

### Manual Testing

```bash
# Quick syntax check
bash -n install.sh

# Dry run (simulates automated install)
./install.sh --dry-run

# Test interactive mode (requires terminal)
./install.sh --setup

# Test with dialog/whiptail explicitly
DIALOG=dialog ./install.sh --dotfiles-only
```

### Existing Tests

The repo includes (in `assets/scripts/`):

| File | Type | Purpose |
|------|------|---------|
| `dots-test.sh` | Shell | Integration smoke test |
| `dots-test.bats` | Bats | Bats unit tests |
| `docker-test.sh` | Shell | Docker-based multi-distro test |

### Running Tests

```bash
# Bats tests
bats assets/scripts/dots-test.bats

# Docker-based tests (tests across Arch, Fedora, Ubuntu)
bash assets/scripts/docker-test.sh
```

### Docker Images

Dockerfiles in `assets/ci/docker/` provide test environments:

| Image | Purpose |
|-------|---------|
| `ubuntu:22.04` | Ubuntu 22.04 LTS |
| `ubuntu:latest` | Latest Ubuntu |
| `fedora:latest` | Latest Fedora |
| `archlinux:latest` | Arch Linux (rolling) |

```bash
docker build -t dotfiles-test -f assets/ci/docker/ubuntu/latest/Dockerfile .
docker run --rm dotfiles-test
```

---

## Debug Mode

```bash
# Verbose bash execution
bash -x install.sh --setup

# Or use the --debug flag (sets DEBUG=true, used by sourced scripts)
./install.sh --debug --dry-run

# Environment variable
DEBUG=1 ./install.sh --dotfiles-only
```

---

## CI/CD Pipeline

GitHub Actions workflows live in `assets/ci/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `cloc.yml` | Push to main + daily | Count lines of code, commit badge |
| `pages.yml` | Push to main | Build & deploy Jekyll docs to GitHub Pages |
| `pages-theme.yml` | Push to main | Alternative theme for Pages |

Docker-based testing runs three distros in parallel, each executing
`install.sh --unattended --minimal` to validate:
1. Package manager detection
2. Dotfile symlink creation
3. Basic tool installation

---

## Release Process

This project uses **semantic versioning** (`MAJOR.MINOR.PATCH`):

1. Update version in `docs/README.md` and `install.sh` header
2. Run test suite (`bash -n`, shellcheck, bats, docker)
3. Tag the release: `git tag -a v2.0.0 -m "v2.0.0"`
4. Push tags: `git push --tags`
5. Write release notes summarizing changes since last tag

Current release: **v2.0.0** (interactive mode major update)

---

## Avoiding Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Using `local` in a `for` loop with `$(...)` | Requires Bash ≥ 4.0; declare before loop or use a function |
| `set -e` terminates on `grep` returning 1 | Use `grep -q ... || true` or test `$?` explicitly |
| `PIPESTATUS` only works in the same command | Capture immediately: `rc=${PIPESTATUS[0]}` |
| Whiptail returns 1 when user presses Cancel | Always use `|| return` when capturing checklist output |
| `source` inside a function changes global state | Use `source` only at global scope or document side effects |
