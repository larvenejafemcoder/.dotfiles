# dotfiles

Modular dotfiles collection managed via stow. Contains configuration for 28+ CLI/GUI tools,
supporting assets (scripts, package lists, CI), and documentation.

## Structure

- `config/` — Configuration files for all tools (symlinked via `install.sh`)
- `assets/` — Supporting data (scripts, package lists, CI, devbox, reference docs)
- `docs/` — Project documentation, package references, roadmap
- `install.sh` — Bootstrap installer that creates XDG dirs and deploys configs via stow
