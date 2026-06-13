#!/usr/bin/env python3
"""GRUB theme management screen."""

from textual import on
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, RichLog, Static

from modules import grub as grub_mod
from tui.widgets.modals import ConfirmModal, InputModal


class GrubScreen(Screen):
    BINDINGS = [Binding("escape", "go_back", "Back")]

    def compose(self) -> Vertical:
        yield Header()
        with Vertical(id="grub-screen"):
            yield Static("GRUB Theme Manager", id="title-text")
            with Vertical(id="grub-stats"):
                yield Static("", id="grub-current")
                yield Static("", id="grub-count")
            with Horizontal(id="grub-actions"):
                yield Button("Install New Theme", id="grub-install", variant="primary")
                yield Button("Apply Installed", id="grub-apply", variant="primary")
                yield Button("Remove Theme", id="grub-remove", variant="error")
                yield Button("Reboot", id="grub-reboot", variant="default")
            with Horizontal(id="grub-actions"):
                yield Button("Set Resolution", id="grub-resolution", variant="default")
                yield Button("Fix Fonts", id="grub-fonts", variant="default")
                yield Button("Reset Default", id="grub-reset", variant="error")
            yield RichLog(id="grub-log", highlight=True, markup=True)
            yield Button("Back to Menu", id="back-button", variant="default")
        yield Footer()

    def on_screen_resume(self) -> None:
        self._refresh_status()

    def _refresh_status(self) -> None:
        status = grub_mod.get_status()
        self.query_one("#grub-current", Static).update(f"[bold]Current theme:[/] [bold #bb9af7]{status['current']}[/]")
        self.query_one("#grub-count", Static).update(f"[bold]Installed themes:[/] [bold #9ece6a]{status['count']}[/]")

    def _log(self, message: str) -> None:
        self.query_one("#grub-log", RichLog).write(message)

    @on(Button.Pressed, "#back-button")
    def go_back(self) -> None:
        self.app.pop_screen()

    def action_go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#grub-install")
    async def handle_install(self) -> None:
        self._log("Launching theme installer...")
        from modules.grub import list_themes
        self._log(list_themes())

    @on(Button.Pressed, "#grub-apply")
    async def handle_apply(self) -> None:
        installed = grub_mod.get_installed_themes()
        if not installed:
            self._log("[red]No installed themes found.[/]")
            return
        self._log(f"Applying theme: {installed[0]}")
        self._log(grub_mod.apply_theme(installed[0]))
        self._refresh_status()

    @on(Button.Pressed, "#grub-remove")
    async def handle_remove(self) -> None:
        installed = grub_mod.get_installed_themes()
        if not installed:
            self._log("[red]No installed themes to remove.[/]")
            return
        theme = installed[-1]
        confirmed = await self.app.push_screen_wait(ConfirmModal("Remove Theme", f"Remove '{theme}'?"))
        if confirmed:
            self._log(grub_mod.remove_theme(theme))
            self._refresh_status()

    @on(Button.Pressed, "#grub-reboot")
    async def handle_reboot(self) -> None:
        confirmed = await self.app.push_screen_wait(ConfirmModal("Reboot", "Reboot system now?"))
        if confirmed:
            self._log("[yellow]Rebooting...[/]")
            grub_mod.reboot()

    @on(Button.Pressed, "#grub-resolution")
    async def handle_resolution(self) -> None:
        result = await self.app.push_screen_wait(InputModal("Set Resolution", "Enter GRUB resolution:", "1920x1080"))
        if result:
            from modules.grub import set_resolution
            self._log(set_resolution(result))

    @on(Button.Pressed, "#grub-fonts")
    async def handle_fonts(self) -> None:
        self._log("[yellow]Fixing GRUB fonts...[/]")
        from modules.grub import fix_fonts
        self._log(fix_fonts())

    @on(Button.Pressed, "#grub-reset")
    async def handle_reset(self) -> None:
        confirmed = await self.app.push_screen_wait(ConfirmModal("Reset", "Reset GRUB to default settings?"))
        if confirmed:
            self._log(grub_mod.reset_default())
            self._refresh_status()
