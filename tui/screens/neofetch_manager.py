#!/usr/bin/env python3
"""Neofetch theme management screen."""

from textual import on
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, RichLog, Static

from tui.widgets.modals import ConfirmModal


class NeofetchScreen(Screen):
    BINDINGS = [Binding("escape", "go_back", "Back")]

    def compose(self) -> Vertical:
        yield Header()
        with Vertical(id="grub-screen"):
            yield Static("Neofetch Theme Manager", id="title-text")
            with Vertical(id="grub-stats"):
                yield Static("", id="neofetch-current")
                yield Static("", id="neofetch-count")
            with Horizontal(id="grub-actions"):
                yield Button("List Themes", id="neofetch-list", variant="primary")
                yield Button("Apply Theme", id="neofetch-apply", variant="primary")
                yield Button("Backup", id="neofetch-backup", variant="default")
                yield Button("Restore", id="neofetch-restore", variant="default")
            yield RichLog(id="neofetch-log", highlight=True, markup=True)
            yield Button("Back to Menu", id="back-button", variant="default")
        yield Footer()

    def on_screen_resume(self) -> None:
        self._refresh_status()

    def _refresh_status(self) -> None:
        from modules.neofetch import get_status
        status = get_status()
        self.query_one("#neofetch-current", Static).update(f"[bold]Current theme:[/] [bold #bb9af7]{status['current']}[/]")
        self.query_one("#neofetch-count", Static).update(f"[bold]Themes available:[/] [bold #9ece6a]{status['total']} ({status['normal_count']} normal, {status['small_count']} small)[/]")

    def _log(self, message: str) -> None:
        self.query_one("#neofetch-log", RichLog).write(message)

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
        self._log(f"Available themes ({len(themes)}): use CLI for exact selection")

    @on(Button.Pressed, "#neofetch-backup")
    async def handle_backup(self) -> None:
        from modules.neofetch import backup_config
        self._log(backup_config())

    @on(Button.Pressed, "#neofetch-restore")
    async def handle_restore(self) -> None:
        confirmed = await self.app.push_screen_wait(ConfirmModal("Restore", "Restore neofetch config from backup?"))
        if confirmed:
            from modules.neofetch import restore_config
            self._log(restore_config())
            self._refresh_status()
