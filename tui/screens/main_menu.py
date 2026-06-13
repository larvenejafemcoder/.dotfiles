#!/usr/bin/env python3
"""Main menu screen for the TUI."""

import time
from typing import List, Optional, Tuple

from textual import on
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, ListItem, ListView, RichLog, Static

from tui.utils.distro_detector import DistroDetector, DistroInfo
from tui.widgets.modals import MessageModal


class InstallerScreen(Screen):
    BINDINGS = [
        Binding("q", "quit_app", "Quit"),
        Binding("i", "quick_install", "Quick Install"),
        Binding("c", "component_selector", "Components"),
        Binding("p", "profile_selector", "Profiles"),
        Binding("d", "distro_info", "Distro Info"),
    ]

    def __init__(self) -> None:
        super().__init__()
        self.distro: Optional[DistroInfo] = None

    def compose(self) -> Vertical:
        yield Header()
        with Vertical(id="title"):
            yield Static("KRNL Dotfiles Installer", id="title-text")
            yield Static("Automated Development Environment Setup", id="subtitle-text")

        with Horizontal(id="menu-container"):
            with Vertical(id="main-menu"):
                items = []
                for icon, name, desc in self.MENU_ITEMS:
                    if not icon and not name:
                        items.append(ListItem(Static(""), classes="menu-separator"))
                    else:
                        item_id = f"menu-{name.lower().replace(' ', '-')}"
                        items.append(ListItem(Static(f"{icon}  {name}"), id=item_id))
                yield ListView(*items, id="menu-list")

            with Vertical(id="menu-info"):
                yield Static("System Info", classes="info-title")
                yield Static("", id="distro-info", classes="info-text-distro")
                yield Static("", classes="info-spacer")
                yield Static("Quick Tips", classes="info-title")
                yield Static("- arrows navigate | Enter select", classes="info-text")
                yield Static("- q quit | i quick install | d distro", classes="info-text")
                yield Static("", classes="info-spacer")
                yield Static("Recent Actions", classes="info-title")
                yield RichLog(id="action-log", markup=True, max_lines=8)

        with Horizontal(id="status-bar"):
            yield Static("Ready", id="status-text")
        yield Footer()

    MENU_ITEMS: List[Tuple[str, str, str]] = [
        ("Quick Install", "Full automated setup"),
        ("", ""),
        ("Component Selector", "Pick individual components"),
        ("Installation Profiles", "Pre-configured setups"),
        ("", ""),
        ("System Check", "Verify compatibility"),
        ("GRUB Themes", "Manage bootloader themes"),
        ("Neofetch", "Customize system info display"),
        ("", ""),
        ("Packages", "Install distribution packages"),
        ("Fonts", "Install Meslo Nerd + JetBrains Mono"),
        ("ZSH", "Oh My Zsh + Powerlevel10k + plugins"),
        ("Neovim", "Neovim + Lazy plugin manager"),
        ("", ""),
        ("Docker", "Install Docker + Compose"),
        ("KVM", "KVM/QEMU + libvirt + virt-manager"),
        ("Hyprland", "Deploy Hyprland desktop"),
        ("i3", "Deploy i3 desktop"),
        ("", ""),
        ("Themes", "Catppuccin + Tahoe + WhiteSur"),
        ("Brave", "Install Brave Browser"),
        ("SSH Keys", "Generate SSH + GPG keys"),
        ("Dev Tools", "Git, Node, Rust, Go, Python"),
        ("", ""),
        ("Settings", "Configure installation options"),
        ("About", "About this tool"),
    ]

    def on_mount(self) -> None:
        self._detect_and_show_distro()
        self._log_action("TUI ready")

    def _detect_and_show_distro(self) -> None:
        self.distro = DistroDetector.detect()
        info_widget = self.query_one("#distro-info")
        info_widget.update(f"{self.distro.name.capitalize()}\n{self.distro.package_manager.upper()}")

    def _log_action(self, message: str) -> None:
        self.query_one("#action-log", RichLog).write(f"[dim]{time.strftime('%H:%M:%S')}[/] {message}")

    def action_quick_install(self) -> None:
        self._log_action("Starting quick installation...")
        components = ["zsh", "starship", "nvim_lazy", "docker", "fonts", "themes"]
        self.app.show_install_loading(components, "Quick Install", self.distro)

    def action_component_selector(self) -> None:
        self._log_action("Opening component selector...")
        if self.distro:
            from tui.screens.component_selector import DistroAwareComponentSelector
            self.app.push_screen(DistroAwareComponentSelector(self.distro))
        else:
            from tui.screens.component_selector import ComponentSelector
            self.app.push_screen(ComponentSelector())

    def action_profile_selector(self) -> None:
        self._log_action("Opening profiles...")
        from tui.screens.profile_selector import ProfileScreen
        self.app.push_screen(ProfileScreen())

    def action_distro_info(self) -> None:
        if self.distro:
            from tui.screens.component_selector import DistroInfoScreen
            self.app.push_screen(DistroInfoScreen(self.distro))
        else:
            self._detect_and_show_distro()
            if self.distro:
                from tui.screens.component_selector import DistroInfoScreen
                self.app.push_screen(DistroInfoScreen(self.distro))

    def action_quit_app(self) -> None:
        self.app.exit()

    def _install_single(self, component: str, label: str) -> None:
        self._log_action(f"Installing {label}...")
        self.app.show_install_loading([component], label, self.distro)

    @on(ListView.Selected)
    async def handle_selected(self, event: ListView.Selected) -> None:
        item_id = event.item.id or ""
        self._log_action(f"Selected: {item_id}")

        match item_id:
            case "menu-quick-install":
                self.action_quick_install()
            case "menu-component-selector":
                self.action_component_selector()
            case "menu-installation-profiles":
                self.action_profile_selector()
            case "menu-system-check":
                from tui.screens.system_check import SystemCheckScreen
                await self.push_screen(SystemCheckScreen())
            case "menu-grub-themes":
                from tui.screens.grub_manager import GrubScreen
                await self.push_screen(GrubScreen())
            case "menu-neofetch":
                from tui.screens.neofetch_manager import NeofetchScreen
                await self.push_screen(NeofetchScreen())
            case "menu-packages":
                self._install_single("everything", "Packages")
            case "menu-fonts":
                self._install_single("fonts", "Fonts")
            case "menu-zsh":
                self._install_single("zsh", "ZSH")
            case "menu-neovim":
                self._install_single("nvim_lazy", "Neovim")
            case "menu-docker":
                self._install_single("docker", "Docker")
            case "menu-kvm":
                self._install_single("kvm", "KVM")
            case "menu-hyprland":
                self._install_single("hyprland", "Hyprland")
            case "menu-i3":
                self._install_single("i3wm", "i3")
            case "menu-themes":
                self._install_single("themes", "Themes")
            case "menu-brave":
                self._install_single("brave", "Brave")
            case "menu-ssh-keys":
                self._install_single("ssh", "SSH Keys")
            case "menu-dev-tools":
                self._install_single("rust_dev", "Dev Tools")
            case "menu-settings":
                from tui.screens.settings import SettingsScreen
                await self.push_screen(SettingsScreen())
            case "menu-about":
                about = f"KRNL Dotfiles Installer\nVersion 1.0\n\nDetected: {self.distro.name if self.distro else 'Unknown'}\nPackage Manager: {self.distro.package_manager.upper() if self.distro else 'auto'}"
                await self.push_screen(MessageModal("About", about))
