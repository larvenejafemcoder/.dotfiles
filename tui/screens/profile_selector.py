#!/usr/bin/env python3
"""Profile selection screen showing pre-built installation profiles."""

from textual import on
from textual.binding import Binding
from textual.containers import Container, Horizontal, ScrollableContainer
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, Static

from modules.components_db import PROFILES
from tui.widgets.modals import MessageModal


class ProfileScreen(Screen):
    BINDINGS = [Binding("escape", "go_back", "Back")]

    def compose(self) -> Container:
        yield Header()
        with Container(id="ps-container"):
            yield Static("Installation Profiles", classes="ps-title")
            yield Static("Pre-defined collections for specific use cases", classes="ps-subtitle")
            with ScrollableContainer(id="ps-grid"):
                for pname, profile in PROFILES.items():
                    with Container(classes="ps-card"):
                        yield Static(f"{profile.icon} {profile.name}", classes="ps-card-title")
                        yield Static(profile.description, classes="ps-card-desc")
                        yield Static(f"Components: {len(profile.components)}", classes="ps-card-stats")
                        with Horizontal(classes="ps-card-actions"):
                            yield Button("View", id=f"ps-view-{pname}", variant="default")
                            yield Button("Select", id=f"ps-select-{pname}", variant="primary")
            with Horizontal(id="ps-bottom"):
                yield Button("Custom Selection", id="ps-custom", variant="default")
                yield Button("Back", id="back-button", variant="default")
        yield Footer()

    def action_go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#back-button")
    def go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#ps-custom")
    def custom(self) -> None:
        self.app.pop_screen()
        from tui.screens.component_selector import ComponentSelector
        self.app.push_screen(ComponentSelector())

    @on(Button.Pressed)
    async def handle_button(self, event: Button.Pressed) -> None:
        bid = event.button.id or ""
        if bid.startswith("ps-view-"):
            pname = bid[8:]
            profile = PROFILES.get(pname)
            if profile:
                details = "\n".join(f"  - {c}" for c in profile.components)
                await self.app.push_screen_wait(MessageModal(f"Profile: {pname}", f"{profile.description}\n\nComponents:\n{details}"))
        elif bid.startswith("ps-select-"):
            pname = bid[10:]
            profile = PROFILES.get(pname)
            if profile:
                self.app.show_install_loading(list(profile.components), pname)
