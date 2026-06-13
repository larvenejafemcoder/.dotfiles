#!/usr/bin/env python3
"""Settings screen placeholder."""

from textual import on
from textual.binding import Binding
from textual.containers import Container
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, Static

from tui.widgets.modals import MessageModal


class SettingsScreen(Screen):
    BINDINGS = [Binding("escape", "go_back", "Back")]

    def compose(self) -> Container:
        yield Header()
        with Container(id="settings-screen"):
            yield Static("Settings", id="title-text")
            yield Static("Configure installation options", id="subtitle-text")
            yield Button("Auto-backup dotfiles", id="setting-backup")
            yield Button("Verbose logging", id="setting-verbose")
            yield Button("Safe mode (dry run)", id="setting-safe")
            yield Button("Configure Git", id="setting-git")
            yield Button("Default profile", id="setting-profile")
            yield Button("Theme", id="setting-theme")
            yield Button("Back to Menu", id="back-button", variant="default")
        yield Footer()

    def action_go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed)
    async def handle_button(self, event: Button.Pressed) -> None:
        bid = event.button.id or ""
        if bid == "back-button":
            self.app.pop_screen()
        elif bid == "setting-backup":
            await self.app.push_screen_wait(MessageModal("Auto-backup", "Toggle auto-backup of existing dotfiles before installation."))
        elif bid == "setting-verbose":
            await self.app.push_screen_wait(MessageModal("Verbose Logging", "Toggle detailed installation logging."))
        elif bid == "setting-safe":
            await self.app.push_screen_wait(MessageModal("Safe Mode", "Toggle dry-run mode (no changes made)."))
        elif bid == "setting-git":
            await self.app.push_screen_wait(MessageModal("Git Config", "Configure git user.name and user.email for the setup."))
        elif bid == "setting-profile":
            await self.app.push_screen_wait(MessageModal("Default Profile", "Select the default installation profile."))
        elif bid == "setting-theme":
            await self.app.push_screen_wait(MessageModal("Theme", "Switch between TUI color themes."))
