#!/usr/bin/env python3
"""TUI - Textual-based dotfiles setup and management utility."""

import sys
import asyncio
from pathlib import Path

from textual import on
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.reactive import var
from textual.screen import ModalScreen, Screen
from textual.widgets import (
    Button,
    Footer,
    Header,
    Input,
    Label,
    ListItem,
    ListView,
    RichLog,
    Static,
)

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))
from modules import DOTFILES_DIR
from modules import grub as grub_mod


# ── Modal ──────────────────────────────────────────────────────────────────


class ConfirmModal(ModalScreen):
    """Generic confirmation modal."""

    def __init__(self, title: str, message: str, confirm_text: str = "Yes") -> None:
        super().__init__()
        self._title = title
        self._message = message
        self._confirm_text = confirm_text

    def compose(self) -> ComposeResult:
        with Vertical(id="modal"):
            yield Static(self._title, id="modal-title")
            yield Static(self._message, id="modal-text")
            with Horizontal(id="modal-buttons"):
                yield Button(self._confirm_text, id="confirm", variant="primary")
                yield Button("Cancel", id="cancel", variant="default")

    @on(Button.Pressed, "#confirm")
    def confirm(self) -> None:
        self.dismiss(True)

    @on(Button.Pressed, "#cancel")
    def cancel(self) -> None:
        self.dismiss(False)


class MessageModal(ModalScreen):
    """Informational modal with a single OK button."""

    def __init__(self, title: str, message: str) -> None:
        super().__init__()
        self._title = title
        self._message = message

    def compose(self) -> ComposeResult:
        with Vertical(id="modal"):
            yield Static(self._title, id="modal-title")
            yield Static(self._message, id="modal-text")
            with Horizontal(id="modal-buttons"):
                yield Button("OK", id="ok", variant="primary")

    @on(Button.Pressed, "#ok")
    def ok(self) -> None:
        self.dismiss(True)


# ── Screens ────────────────────────────────────────────────────────────────


class GrubScreen(Screen):
    """GRUB Theme Management screen."""

    BINDINGS = [
        Binding("escape", "go_back", "Back"),
    ]

    def compose(self) -> ComposeResult:
        yield Header()
        with Vertical(id="grub-screen"):
            yield Static("🎨 GRUB Theme Manager", id="title-text")
            with Vertical(id="grub-stats"):
                yield Static("", id="grub-current")
                yield Static("", id="grub-count")
            with Horizontal(id="grub-actions"):
                yield Button("📥 Install New Theme", id="grub-install", variant="primary")
                yield Button("✅ Apply Installed", id="grub-apply", variant="primary")
                yield Button("🗑 Remove Theme", id="grub-remove", variant="error")
                yield Button("🔄 Reboot", id="grub-reboot", variant="default")
            with Horizontal(id="grub-actions"):
                yield Button("🖥 Set Resolution", id="grub-resolution", variant="default")
                yield Button("🔤 Fix Fonts", id="grub-fonts", variant="default")
                yield Button("🔙 Reset Default", id="grub-reset", variant="error")
            yield RichLog(id="grub-log", highlight=True, markup=True)
            yield Button("← Back to Menu", id="back-button", variant="default")
        yield Footer()

    def on_screen_resume(self) -> None:
        self._refresh_status()

    def _refresh_status(self) -> None:
        status = grub_mod.get_status()
        current = self.query_one("#grub-current", Static)
        count = self.query_one("#grub-count", Static)
        current.update(f"[bold]Current theme:[/] [bold #bb9af7]{status['current']}[/]")
        count.update(f"[bold]Installed themes:[/] [bold #9ece6a]{status['count']}[/]")

    def _log(self, message: str) -> None:
        log = self.query_one("#grub-log", RichLog)
        log.write(message)

    @on(Button.Pressed, "#back-button")
    def go_back(self) -> None:
        self.app.pop_screen()

    def action_go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#grub-install")
    async def handle_install(self) -> None:
        self._log("Launching theme installer...")
        from modules.grub import list_themes
        output = list_themes()
        self._log(output)

    @on(Button.Pressed, "#grub-apply")
    async def handle_apply(self) -> None:
        installed = grub_mod.get_installed_themes()
        if not installed:
            self._log("[red]No installed themes found.[/]")
            return
        theme = installed[0] if installed else ""
        self._log(f"Applying theme: {theme}")
        msg = grub_mod.apply_theme(theme)
        self._log(msg)
        self._refresh_status()

    @on(Button.Pressed, "#grub-remove")
    async def handle_remove(self) -> None:
        installed = grub_mod.get_installed_themes()
        if not installed:
            self._log("[red]No installed themes to remove.[/]")
            return
        theme = installed[-1] if installed else ""
        confirmed = await self.app.push_screen_wait(
            ConfirmModal("Remove Theme", f"Remove '{theme}'?")
        )
        if confirmed:
            msg = grub_mod.remove_theme(theme)
            self._log(msg)
            self._refresh_status()

    @on(Button.Pressed, "#grub-reboot")
    async def handle_reboot(self) -> None:
        confirmed = await self.app.push_screen_wait(
            ConfirmModal("Reboot", "Reboot system now?")
        )
        if confirmed:
            self._log("[yellow]Rebooting...[/]")
            grub_mod.reboot()

    @on(Button.Pressed, "#grub-resolution")
    async def handle_resolution(self) -> None:
        self._log("[yellow]Resolution setting not yet implemented in TUI.[/]")
        self._log("Use the bash script directly: sudo bash scripts/grub.sh")

    @on(Button.Pressed, "#grub-fonts")
    async def handle_fonts(self) -> None:
        self._log("[yellow]Font fix not yet implemented in TUI.[/]")
        self._log("Use the bash script directly: sudo bash scripts/grub.sh")

    @on(Button.Pressed, "#grub-reset")
    async def handle_reset(self) -> None:
        confirmed = await self.app.push_screen_wait(
            ConfirmModal("Reset", "Reset GRUB to default settings?")
        )
        if confirmed:
            msg = grub_mod.reset_default()
            self._log(msg)
            self._refresh_status()


class NeofetchScreen(Screen):
    """Neofetch Theme Management screen."""

    BINDINGS = [
        Binding("escape", "go_back", "Back"),
    ]

    def compose(self) -> ComposeResult:
        yield Header()
        with Vertical(id="grub-screen"):
            yield Static("🖼 Neofetch Theme Manager", id="title-text")
            with Vertical(id="grub-stats"):
                yield Static("", id="neofetch-current")
                yield Static("", id="neofetch-count")
            with Horizontal(id="grub-actions"):
                yield Button("📋 List Themes", id="neofetch-list", variant="primary")
                yield Button("✅ Apply Theme", id="neofetch-apply", variant="primary")
                yield Button("📦 Backup", id="neofetch-backup", variant="default")
                yield Button("↩ Restore", id="neofetch-restore", variant="default")
            yield RichLog(id="neofetch-log", highlight=True, markup=True)
            yield Button("← Back to Menu", id="back-button", variant="default")
        yield Footer()

    def on_screen_resume(self) -> None:
        self._refresh_status()

    def _refresh_status(self) -> None:
        from modules.neofetch import get_status
        status = get_status()
        current = self.query_one("#neofetch-current", Static)
        count = self.query_one("#neofetch-count", Static)
        current.update(f"[bold]Current theme:[/] [bold #bb9af7]{status['current']}[/]")
        count.update(f"[bold]Themes available:[/] [bold #9ece6a]{status['total']} ({status['normal_count']} normal, {status['small_count']} small)[/]")

    def _log(self, message: str) -> None:
        log = self.query_one("#neofetch-log", RichLog)
        log.write(message)

    @on(Button.Pressed, "#back-button")
    def go_back(self) -> None:
        self.app.pop_screen()

    def action_go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#neofetch-list")
    async def handle_list(self) -> None:
        from modules.neofetch import list_themes
        self._log(list_themes())

    @on(Button.Pressed, "#neofetch-apply")
    async def handle_apply(self) -> None:
        from modules.neofetch import get_status
        status = get_status()
        themes = status["normal"] + status["small"]
        if not themes:
            self._log("[red]No themes found.[/]")
            return

        theme_names = "\n".join(f"  {t['name']} ({t['category']})" for t in themes[:20])
        self._log(f"Available themes:\n{theme_names}\n\n[dim]Use CLI for exact selection: bash scripts/neofetch.sh --apply \"Name\"[/]")

    @on(Button.Pressed, "#neofetch-backup")
    async def handle_backup(self) -> None:
        from modules.neofetch import backup_config
        msg = backup_config()
        self._log(msg)

    @on(Button.Pressed, "#neofetch-restore")
    async def handle_restore(self) -> None:
        confirmed = await self.app.push_screen_wait(
            ConfirmModal("Restore", "Restore neofetch config from backup?")
        )
        if confirmed:
            from modules.neofetch import restore_config
            msg = restore_config()
            self._log(msg)
            self._refresh_status()


class InstallerScreen(Screen):
    """Main menu screen with setup options."""

    MENU_ITEMS = [
        ("📦 Packages", "Install distribution packages"),
        ("🔤 Fonts", "Install Meslo Nerd + JetBrains Mono"),
        ("🐚 ZSH", "Oh My Zsh + Powerlevel10k + plugins"),
        ("🖼 Neofetch", "Browse and apply neofetch themes"),
        ("🎨 GRUB Themes", "Install and manage GRUB themes"),
        ("✍ Neovim", "Neovim + Lazy plugin manager"),
        ("⚡ Everything", "Full dotfiles deployment"),
    ]

    BINDINGS = [
        Binding("q", "quit_app", "Quit"),
    ]

    def compose(self) -> ComposeResult:
        yield Header()
        with Vertical(id="title"):
            yield Static("Dotfiles Setup Utility", id="title-text")
            yield Static("Interactive TUI", id="subtitle-text")
        with Vertical(id="main-menu"):
            yield ListView(*[
                ListItem(Label(f"  {icon}  {name}"), id=f"menu-{name.lower().split()[0]}")
                for icon, name, _ in self.MENU_ITEMS
            ])
        with Horizontal(id="status-bar"):
            yield Static("↑↓ navigate · Enter select · q quit", id="status-text")
        yield Footer()

    @on(ListView.Selected)
    async def handle_selected(self, event: ListView.Selected) -> None:
        item_id = event.item.id or ""
        match item_id:
            case "menu-packages":
                await self._run_task("📦 Installing packages...", self._install_packages)
            case "menu-fonts":
                await self._run_task("🔤 Installing fonts...", self._install_fonts)
            case "menu-zsh":
                await self._run_task("🐚 Setting up ZSH...", self._setup_zsh)
            case "menu-neofetch":
                await self.push_screen(NeofetchScreen())
            case "menu-grub":
                await self.push_screen(GrubScreen())
            case "menu-neovim":
                await self._run_task("✍ Setting up Neovim...", self._setup_neovim)
            case "menu-everything":
                await self._run_task("⚡ Running full install...", self._install_everything)

    async def _run_task(self, label: str, coro) -> None:
        self._show_message("Working...", f"{label}\n\nThis may take a while.")
        result = await coro()
        self.dismiss()
        await self.app.push_screen_wait(
            MessageModal("Complete", result or "Done!")
        )

    def _show_message(self, title: str, message: str) -> None:
        try:
            from textual.widgets import Label
            status = self.query_one("#status-text")
            if status:
                status.update(message)
        except Exception:
            pass

    async def _install_packages(self) -> str:
        from modules.packages import install_all
        return install_all()

    async def _install_fonts(self) -> str:
        from modules.fonts import install_fonts
        return install_fonts()

    async def _setup_zsh(self) -> str:
        from modules.shell import setup_zsh
        return setup_zsh()

    async def _setup_neovim(self) -> str:
        from modules.lazyvim import setup_neovim
        return setup_neovim()

    async def _install_everything(self) -> str:
        install_script = DOTFILES_DIR / "install.sh"
        if not install_script.is_file():
            return f"install.sh not found at {install_script}"
        import subprocess as sp
        result = sp.run(
            [str(install_script), "--unattended"],
            capture_output=True, text=True, timeout=600,
        )
        return result.stdout.strip() or result.stderr.strip() or "Full install completed."

    def action_quit_app(self) -> None:
        self.app.exit()


# ── App ────────────────────────────────────────────────────────────────────


class KrnlInstaller(App):
    """KRNL Installer - TUI for dotfiles deployment and GRUB management."""

    CSS_PATH = "assets/styles.tcss"
    TITLE = "KRNL Installer"
    SCREENS = {"main": InstallerScreen}

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("escape", "back", "Back"),
    ]

    def on_ready(self) -> None:
        self.push_screen("main")

    def action_quit(self) -> None:
        self.exit()

    def action_back(self) -> None:
        if len(self.screen_stack) > 1:
            self.pop_screen()


def main() -> None:
    app = KrnlInstaller()
    app.run()


if __name__ == "__main__":
    main()
