"""Component Database - defines all installable dotfile components and profiles."""

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class DotfileComponent:
    """A single installable dotfile component."""
    name: str
    description: str
    category: str
    target: str = ""
    dependencies: list[str] = field(default_factory=list)
    conflicts: list[str] = field(default_factory=list)
    install_size_kb: int = 0
    tags: list[str] = field(default_factory=list)


@dataclass
class Profile:
    """Pre-defined collection of components for a use case."""
    name: str
    description: str
    components: list[str]
    icon: str = ""
    color: str = "blue"


DOTFILES_DATABASE: dict[str, dict[str, DotfileComponent]] = {
    "Shell Environments": {
        "zsh": DotfileComponent(
            name="zsh",
            description="Oh My Zsh + syntax highlighting + autosuggestions",
            category="Shell Environments",
            dependencies=["zsh", "git", "curl"],
            tags=["shell", "terminal", "productivity"],
        ),
        "bash": DotfileComponent(
            name="bash",
            description="Enhanced .bashrc with aliases and functions",
            category="Shell Environments",
            dependencies=["bash>=5.0"],
            tags=["shell", "terminal"],
        ),
        "fish": DotfileComponent(
            name="fish",
            description="Fish shell config with Fisher plugin manager",
            category="Shell Environments",
            dependencies=["fish", "curl"],
            tags=["shell", "modern"],
        ),
        "starship": DotfileComponent(
            name="starship",
            description="Cross-shell prompt (works with zsh/bash/fish)",
            category="Shell Environments",
            dependencies=["starship"],
            tags=["shell", "prompt"],
        ),
    },
    "Neovim Configurations": {
        "nvim_lazy": DotfileComponent(
            name="nvim_lazy",
            description="LazyVim - modern Neovim IDE experience",
            category="Neovim Configurations",
            dependencies=["neovim>=0.9.0", "git", "curl"],
            conflicts=["nvim_nvchad", "nvim_astro", "nvim_basic"],
            install_size_kb=15000,
            tags=["editor", "ide", "lua"],
        ),
        "nvim_nvchad": DotfileComponent(
            name="nvim_nvchad",
            description="NvChad - fast Neovim with beautiful UI",
            category="Neovim Configurations",
            dependencies=["neovim>=0.9.0", "git"],
            conflicts=["nvim_lazy", "nvim_astro", "nvim_basic"],
            install_size_kb=12000,
            tags=["editor", "fast"],
        ),
        "nvim_astro": DotfileComponent(
            name="nvim_astro",
            description="AstroNvim - aesthetic feature-rich config",
            category="Neovim Configurations",
            dependencies=["neovim>=0.8.0", "git"],
            conflicts=["nvim_lazy", "nvim_nvchad", "nvim_basic"],
            install_size_kb=10000,
            tags=["editor", "aesthetic"],
        ),
        "nvim_basic": DotfileComponent(
            name="nvim_basic",
            description="Minimal Neovim with essential plugins",
            category="Neovim Configurations",
            dependencies=["neovim>=0.8.0"],
            conflicts=["nvim_lazy", "nvim_nvchad", "nvim_astro"],
            install_size_kb=3000,
            tags=["editor", "minimal"],
        ),
    },
    "Git Configurations": {
        "git_enhanced": DotfileComponent(
            name="git_enhanced",
            description="Full .gitconfig with aliases, difftools, and hooks",
            category="Git Configurations",
            dependencies=["git>=2.30"],
            install_size_kb=50,
            tags=["vcs", "productivity"],
        ),
        "git_aliases": DotfileComponent(
            name="git_aliases",
            description="Productive Git shorthand aliases",
            category="Git Configurations",
            dependencies=["git>=2.0"],
            install_size_kb=20,
            tags=["vcs", "aliases"],
        ),
        "git_ignore_global": DotfileComponent(
            name="git_ignore_global",
            description="Global .gitignore for OS and IDE files",
            category="Git Configurations",
            dependencies=["git>=2.0"],
            install_size_kb=30,
            tags=["vcs", "gitignore"],
        ),
    },
    "Terminal Multiplexers": {
        "tmux": DotfileComponent(
            name="tmux",
            description="Tmux config with TPM plugin manager",
            category="Terminal Multiplexers",
            dependencies=["tmux>=3.0", "git"],
            install_size_kb=100,
            tags=["multiplexer", "terminal"],
        ),
        "tmux_continuum": DotfileComponent(
            name="tmux_continuum",
            description="Tmux with persist/restore via continuum + resurrect",
            category="Terminal Multiplexers",
            dependencies=["tmux>=3.0", "git"],
            install_size_kb=150,
            tags=["multiplexer", "persistence"],
        ),
    },
    "Window Managers": {
        "i3wm": DotfileComponent(
            name="i3wm",
            description="i3 gaps config with polybar status bar",
            category="Window Managers",
            dependencies=["i3-wm"],
            install_size_kb=50,
            tags=["wm", "tiling"],
        ),
        "hyprland": DotfileComponent(
            name="hyprland",
            description="Hyprland dynamic tiling Wayland compositor",
            category="Window Managers",
            dependencies=["hyprland", "waybar"],
            install_size_kb=100,
            tags=["wm", "wayland", "modern"],
        ),
        "bspwm": DotfileComponent(
            name="bspwm",
            description="BSPWM with sxhkd and polybar",
            category="Window Managers",
            dependencies=["bspwm", "sxhkd"],
            install_size_kb=40,
            tags=["wm", "binary"],
        ),
    },
    "Development Environment": {
        "python_dev": DotfileComponent(
            name="python_dev",
            description="Python setup with pyenv, poetry, ruff",
            category="Development Environment",
            dependencies=["python3", "pip"],
            install_size_kb=100,
            tags=["python", "development"],
        ),
        "nodejs_dev": DotfileComponent(
            name="nodejs_dev",
            description="Node.js with nvm, npm, yarn/pnpm",
            category="Development Environment",
            dependencies=["nodejs", "npm"],
            install_size_kb=80,
            tags=["javascript", "nodejs"],
        ),
        "rust_dev": DotfileComponent(
            name="rust_dev",
            description="Rust with cargo, rust-analyzer",
            category="Development Environment",
            dependencies=["rustup", "cargo"],
            install_size_kb=50,
            tags=["rust", "systems"],
        ),
        "go_dev": DotfileComponent(
            name="go_dev",
            description="Go with gopls, delve, golangci-lint",
            category="Development Environment",
            dependencies=["golang"],
            install_size_kb=40,
            tags=["go", "golang"],
        ),
    },
    "Terminal Tools": {
        "alacritty": DotfileComponent(
            name="alacritty",
            description="GPU-accelerated terminal emulator config",
            category="Terminal Tools",
            dependencies=["alacritty"],
            install_size_kb=20,
            tags=["terminal", "gpu"],
        ),
        "kitty": DotfileComponent(
            name="kitty",
            description="Feature-rich GPU terminal with ligatures",
            category="Terminal Tools",
            dependencies=["kitty"],
            install_size_kb=30,
            tags=["terminal", "gpu"],
        ),
        "wezterm": DotfileComponent(
            name="wezterm",
            description="GPU terminal in Rust with Lua config",
            category="Terminal Tools",
            dependencies=["wezterm"],
            install_size_kb=40,
            tags=["terminal", "rust", "lua"],
        ),
    },
    "Productivity Tools": {
        "taskwarrior": DotfileComponent(
            name="taskwarrior",
            description="Task management system configuration",
            category="Productivity Tools",
            dependencies=["task"],
            install_size_kb=10,
            tags=["productivity", "tasks"],
        ),
        "timewarrior": DotfileComponent(
            name="timewarrior",
            description="Time tracking with Taskwarrior integration",
            category="Productivity Tools",
            dependencies=["timew"],
            install_size_kb=5,
            tags=["productivity", "time"],
        ),
        "system_aliases": DotfileComponent(
            name="system_aliases",
            description="Common bash aliases and functions for daily use",
            category="Productivity Tools",
            install_size_kb=15,
            tags=["system", "aliases"],
        ),
        "env_vars": DotfileComponent(
            name="env_vars",
            description="Environment variables configuration",
            category="Productivity Tools",
            install_size_kb=10,
            tags=["environment"],
        ),
    },
}

PROFILES: dict[str, Profile] = {
    "Full Development Suite": Profile(
        name="Full Development Suite",
        description="Complete dev environment: ZSH, Neovim, Git, Tmux + all language toolchains",
        components=[
            "zsh", "starship", "nvim_lazy", "git_enhanced", "tmux",
            "python_dev", "nodejs_dev", "rust_dev", "go_dev",
            "alacritty", "taskwarrior", "system_aliases",
        ],
        icon="🚀",
        color="green",
    ),
    "Web Developer": Profile(
        name="Web Developer",
        description="Web dev essentials: Node.js, AstroNvim, Git, modern terminal",
        components=[
            "bash", "nvim_astro", "git_enhanced", "nodejs_dev",
            "kitty", "system_aliases",
        ],
        icon="🌐",
        color="blue",
    ),
    "Data Scientist": Profile(
        name="Data Scientist",
        description="Data science: Python, Neovim, Tmux, WezTerm",
        components=[
            "zsh", "nvim_lazy", "git_enhanced", "python_dev",
            "wezterm", "tmux", "system_aliases",
        ],
        icon="📊",
        color="purple",
    ),
    "System Administrator": Profile(
        name="System Administrator",
        description="Sysadmin tools: Tmux, Vim, Git, task management",
        components=[
            "bash", "git_enhanced", "tmux_continuum",
            "taskwarrior", "system_aliases", "env_vars",
        ],
        icon="🖥",
        color="yellow",
    ),
    "Minimal Setup": Profile(
        name="Minimal Setup",
        description="Lightweight: Bash, basic Git aliases, system aliases",
        components=[
            "bash", "git_aliases", "system_aliases",
        ],
        icon="⚡",
        color="cyan",
    ),
    "Window Manager Enthusiast": Profile(
        name="Window Manager Enthusiast",
        description="WM setup: ZSH, Neovim, Git, i3/Hyprland, Alacritty",
        components=[
            "zsh", "nvim_lazy", "git_enhanced", "i3wm", "hyprland",
            "alacritty", "tmux", "system_aliases",
        ],
        icon="🪟",
        color="red",
    ),
}


def get_component(name: str) -> DotfileComponent | None:
    for category in DOTFILES_DATABASE.values():
        if name in category:
            return category[name]
    return None


def get_components_by_tag(tag: str) -> list[DotfileComponent]:
    return [
        comp for category in DOTFILES_DATABASE.values()
        for comp in category.values()
        if tag in comp.tags
    ]


def resolve_dependencies(selected: list[str]) -> list[str]:
    """Topological sort resolving component dependencies."""
    resolved: list[str] = []
    visited: set[str] = set()
    temp: set[str] = set()

    def visit(node: str) -> None:
        if node in temp:
            return
        if node in visited:
            return
        comp = get_component(node)
        if comp is None:
            visited.add(node)
            resolved.append(node)
            return
        temp.add(node)
        for dep in comp.dependencies:
            dep_name = dep.split(">=")[0].split("==")[0].strip()
            dep_comp = next(
                (c for cat in DOTFILES_DATABASE.values() for c_name, c in cat.items() if c_name == dep_name),
                None,
            )
            if dep_comp and dep_comp.name not in visited:
                visit(dep_comp.name)
        temp.remove(node)
        visited.add(node)
        resolved.append(node)

    for comp_name in selected:
        if comp_name not in visited:
            visit(comp_name)
    return resolved


def check_conflicts(selected: list[str]) -> list[tuple[str, str]]:
    conflicts: list[tuple[str, str]] = []
    for name in selected:
        comp = get_component(name)
        if comp:
            for conflict in comp.conflicts:
                if conflict in selected:
                    conflicts.append((name, conflict))
    return conflicts
