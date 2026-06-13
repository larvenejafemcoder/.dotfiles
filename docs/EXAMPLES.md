# Examples

> **Documentation version:** 2.0.0

---

## Scenario 1: Fresh Ubuntu 24.04 on WSL2

```bash
# 1. Install dependencies
sudo apt update && sudo apt install -y git curl stow dialog

# 2. Clone
git clone https://github.com/your-org/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 3. Deploy dotfiles interactively
./install.sh --dotfiles-only
```

Select: `.zshrc`, `.bashrc`, `.tmux.conf`, `.gitconfig`

```bash
# 4. Install dev tools
./install.sh --tools-only
```

Select: `nodejs`, `rust`, `starship`, `cli`

Expected output:
```
OK    Dev tools installation complete
  ✓ Node.js (nvm)
  ✓ Rust
  ✓ Starship
  ✓ eza
  ✓ bat
  ✓ fzf
  ✓ rg
  ✓ fd
  ✓ lazygit
  ✓ jq
  ✓ zoxide
```

Estimated time: 3-5 minutes (depends on download speed)

---

## Scenario 2: Air-Gapped RHEL Server

```bash
# On a machine with network, prepare:
./install.sh --dotfiles-only --offline    # Symlinks work without network

# Copy the repo to the air-gapped machine:
scp -r ~/.dotfiles server:~/

# On the server:
./install.sh --setup --offline --dotfiles-only
```

Packages that require network (nvm, rustup, go tarball) are skipped gracefully:

```
WARN  Offline — skipping: nodejs
WARN  Offline — skipping: rust
```

---

## Scenario 3: Arch Linux Desktop with Hyprland

```bash
# Full automated desktop setup
./install.sh --unattended --profile hyprland --rice

# Or interactive (choose what you need)
./install.sh --setup
```

Pipeline on Arch:
1. `pacman -S --noconfirm --needed` from `config/packages/arch.txt`
2. Dotfile symlinks
3. Zsh + Starship prompt
4. Meslo Nerd Font
5. Dev tools (Node, Rust, Go)
6. Docker (from get.docker.com)
7. KVM/libvirt setup
8. Hyprland desktop profile
9. WhiteSur GTK theme
10. Neovim (latest)
11. Brave Browser
12. SSH key generation
13. Gruvbox ricing

---

## Scenario 4: CI Container Image

```dockerfile
FROM ubuntu:22.04

RUN apt update && apt install -y git curl stow dialog
RUN git clone https://github.com/your-org/dotfiles.git /opt/dotfiles
RUN cd /opt/dotfiles && ./install.sh --unattended --minimal
```

Build:

```bash
docker build -t dev-image .
```

This produces a minimal image with dotfiles + packages but no desktop
components. The `--minimal` flag disables everything except packages and
dotfiles.

---

## Scenario 5: Sync Dotfiles Across 3 Machines

```bash
# On machine A (workstation):
./install.sh --dotfiles-only
# Select: .zshrc, .tmux.conf, .config/alacritty, .config/nvim, .config/starship.toml

# On machine B (laptop):
git pull
./install.sh --repeat         # Same selections as A

# On machine C (server, no GUI):
./install.sh --repeat --dotfiles-only --offline
# Only symlinks; skips alacritty/nvim (GUI tools) silently
```

---

## Scenario 6: Minimal Server Bootstrap

```bash
# Only packages + dotfiles, nothing else
./install.sh --unattended --minimal
```

This is equivalent to:

```bash
./install.sh --unattended \
  --no-theme --no-fonts --no-starship --no-zsh \
  --no-dev --no-docker --no-kvm --no-desktop \
  --no-neovim --no-brave --no-ssh
```

---

## Scenario 7: macOS with Homebrew

The script primarily targets Linux, but `scripts/core/detect.sh` and
`scripts/pkg/manager.sh` have partial macOS support:

```bash
# On macOS, install GNU tools first:
brew install bash git curl stow dialog
bash install.sh --setup
```

Package management falls through to `apt` as default — not fully supported
yet.

---

## Scenario 8: Docker-Based Testing

```bash
# Test on Ubuntu latest
docker build -t dotfiles-test -f assets/ci/docker/ubuntu/latest/Dockerfile .
docker run --rm dotfiles-test

# Test on Arch
docker build -t dotfiles-test-arch -f assets/ci/docker/arch/Dockerfile .
docker run --rm dotfiles-test-arch
```

The Dockerfiles run `install.sh --unattended --minimal` as their CMD.

---

## Timing Benchmarks

| Scenario | Tools selected | Time (typical) |
|----------|---------------|----------------|
| Dotfiles only | 5 config files | < 5 seconds |
| Dev tools (nvm, rust, starship) | nodejs, rust, starship | 2-3 minutes |
| Dev tools (full) | nodejs, rust, go, starship, neovim, docker, cli | 5-8 minutes |
| Full automated | All components | 8-15 minutes |
| Minimal (CI) | Packages + dotfiles | 30-60 seconds |
| Offline | Any | < 10 seconds |

Times depend on network speed and CPU. Rust installation (compiling) is the
slowest step.
