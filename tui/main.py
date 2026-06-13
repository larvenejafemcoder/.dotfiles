#!/usr/bin/env python3
"""KRNL Dotfiles Installer TUI - main app entry point."""

import asyncio

from textual import work
from textual.app import App
from textual.binding import Binding
from typing import List, Optional

from modules.loading_animations import AnimatedLoadingScreen
from tui.screens.install_progress import EnhancedInstallProgressScreen
from tui.screens.main_menu import InstallerScreen
from tui.utils.distro_detector import DistroDetector, DistroInfo


class KrnlInstaller(App):
    CSS_PATH = "tui/styles/styles.tcss"
    TITLE = "KRNL Installer"
    SCREENS = {"main": InstallerScreen}

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("escape", "back", "Back"),
        Binding("ctrl+r", "refresh", "Refresh"),
    ]

    def on_mount(self) -> None:
        self._show_startup_animation()

    @work(thread=False)
    async def _show_startup_animation(self) -> None:
        loader = AnimatedLoadingScreen(
            message="Initializing KRNL Installer",
            submessage="Detecting system and loading components...",
            animation="matrix",
            auto_advance=True,
        )
        await self.push_screen(loader)

        distro = DistroDetector.detect()
        steps = [
            (f"Detected: {distro.name.capitalize()}...", 25),
            (f"Package manager: {distro.package_manager.upper()}...", 50),
            ("Loading component database...", 75),
            ("Ready!", 100),
        ]

        for msg, pct in steps:
            if hasattr(loader, 'set_progress'):
                loader.set_progress(pct, msg)
            await asyncio.sleep(0.5)

        await self.pop_screen()
        self.push_screen("main")

    @work(thread=False)
    async def show_install_loading(self, components: List[str], profile_name: Optional[str] = None,
                                    distro: Optional[DistroInfo] = None) -> None:
        loader = AnimatedLoadingScreen(
            message="Preparing Installation",
            submessage=f"Processing {len(components)} components on {distro.name if distro else 'system'}...",
            animation="breathing",
            auto_advance=False,
        )
        await self.push_screen(loader)

        steps = [
            ("Resolving dependencies...", 20),
            ("Checking conflicts...", 40),
            ("Preparing backup...", 60),
            ("Verifying space...", 80),
            ("Ready to install", 100),
        ]

        for msg, pct in steps:
            if hasattr(loader, 'set_progress'):
                loader.set_progress(pct, msg)
            await asyncio.sleep(0.3)

        await self.pop_screen()
        self.push_screen(EnhancedInstallProgressScreen(components, profile_name, distro))

    def action_quit(self) -> None:
        self.exit()

    def action_back(self) -> None:
        if len(self.screen_stack) > 1:
            self.pop_screen()

    def action_refresh(self) -> None:
        self.call_from_thread(self.refresh)


def main() -> None:
    app = KrnlInstaller()
    app.run()


if __name__ == "__main__":
    main()
