#!/usr/bin/env python3
"""Enhanced installation progress screen with live feedback."""

import asyncio
import time
from typing import Dict, List, Optional, Tuple

from textual import work
from textual.binding import Binding
from textual.containers import Container, Horizontal, ScrollableContainer
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, ProgressBar, Static

from modules.component_manager import DependencyResolver
from tui.utils.distro_detector import DistroInfo
from tui.utils.installer_backend import install_component
from tui.widgets.modals import ConfirmModal, MessageModal


class EnhancedInstallProgressScreen(Screen):
    BINDINGS = [
        Binding("escape", "cancel_install", "Cancel"),
        Binding("ctrl+c", "cancel_install", "Cancel"),
    ]

    def __init__(self, components: List[str], profile_name: Optional[str] = None,
                 distro: Optional[DistroInfo] = None) -> None:
        super().__init__()
        self.components = components
        self.profile_name = profile_name
        self.distro = distro
        self.is_cancelled = False
        self.installation_results: Dict[str, bool] = {}
        self.failed_components: List[Tuple[str, str]] = []

    def compose(self) -> Container:
        yield Header()
        with Container(id="ip-container"):
            yield Static("Installing Components", classes="ip-title")
            if self.profile_name:
                yield Static(f"Profile: {self.profile_name}", classes="ip-profile")
            if self.distro:
                yield Static(f"System: {self.distro.name.capitalize()}", classes="ip-distro")
            yield Static(f"Total: {len(self.components)} components", classes="ip-total")

            with Container(id="ip-progress-section"):
                yield ProgressBar(total=100, show_percentage=True, id="ip-progress-bar")
                yield Static("", id="ip-progress-text", classes="ip-progress-text")

            with Container(id="ip-current-section"):
                yield Static("Currently installing:", classes="ip-current-label")
                yield Static("", id="ip-current-component", classes="ip-current-component")

            with Horizontal(id="ip-stats"):
                yield Static("Completed: 0", id="ip-completed")
                yield Static("Failed: 0", id="ip-failed")
                yield Static("Remaining: 0", id="ip-remaining")

            with Container(id="ip-console"):
                yield Static("Installation Log:", classes="ip-console-label")
                yield ScrollableContainer(Static("", id="ip-console-text"), id="ip-console-scroll")

            with Horizontal(id="ip-buttons"):
                yield Button("Cancel", id="cancel-button", variant="error")

        yield Footer()

    def on_mount(self) -> None:
        self.run_install()

    def action_cancel_install(self) -> None:
        async def confirm_cancel():
            confirmed = await self.app.push_screen_wait(
                ConfirmModal("Cancel Installation",
                            "Are you sure? This may leave partial state.",
                            "Yes, Cancel", "No, Continue", danger=True)
            )
            if confirmed:
                self.is_cancelled = True
                self._log("Installation cancelled by user")

        asyncio.create_task(confirm_cancel())

    @on(Button.Pressed, "#cancel-button")
    def handle_cancel(self) -> None:
        self.action_cancel_install()

    @work(thread=False)
    async def run_install(self) -> None:
        resolver = DependencyResolver()

        self._log(f"Detected system: {self.distro.name if self.distro else 'Unknown'}")
        self._log(f"Package manager: {self.distro.package_manager if self.distro else 'auto'}")

        try:
            resolved = resolver.resolve(self.components)
            conflicts = resolver.conflicts(resolved)
            if conflicts:
                for c1, c2 in conflicts:
                    self._log(f"  ! {c1} <-> {c2}")
                await self.app.push_screen_wait(MessageModal("Conflicts", f"Cannot proceed: {len(conflicts)} conflicts.", 3))
                await asyncio.sleep(2)
                self.app.pop_screen()
                return
        except Exception as e:
            self._log(f"Dependency resolution failed: {e}")
            await asyncio.sleep(2)
            self.app.pop_screen()
            return

        total = len(resolved)
        completed = 0
        failed = 0
        self._update_stats(completed, failed, total)

        for idx, cname in enumerate(resolved):
            if self.is_cancelled:
                break

            self._update_current(cname, "installing")
            self._log(f"Installing: {cname}")

            try:
                success, log_line = await install_component(cname)
                if success:
                    self._log(f"  {cname} installed: {log_line}")
                    self.installation_results[cname] = True
                    completed += 1
                else:
                    self._log(f"  {cname} failed: {log_line}")
                    self.installation_results[cname] = False
                    self.failed_components.append((cname, log_line))
                    failed += 1
            except Exception as e:
                self._log(f"  {cname} error: {e}")
                self.installation_results[cname] = False
                self.failed_components.append((cname, str(e)))
                failed += 1

            self._update_stats(completed, failed, total - (completed + failed))
            pct = int(((completed + failed) / total) * 100)
            self.query_one("#ip-progress-bar").update(progress=pct)
            await asyncio.sleep(0.1)

        self._show_summary(completed, failed)

    def _update_current(self, cname: str, status: str) -> None:
        icons = {"installing": "*", "success": "OK", "failed": "FAIL", "cancelled": "CANCELLED"}
        self.query_one("#ip-current-component").update(f"{icons.get(status, '?')} {cname}")

    def _update_stats(self, completed: int, failed: int, remaining: int) -> None:
        self.query_one("#ip-completed").update(f"Completed: {completed}")
        self.query_one("#ip-failed").update(f"Failed: {failed}")
        self.query_one("#ip-remaining").update(f"Remaining: {remaining}")

    def _log(self, text: str) -> None:
        console_text = self.query_one("#ip-console-text")
        current = console_text.renderable or ""
        ts = time.strftime("%H:%M:%S")
        console_text.update(f"{current}\n[{ts}] {text}" if current else f"[{ts}] {text}")
        self.query_one("#ip-console-scroll").scroll_end(animate=False)

    def _show_summary(self, completed: int, failed: int) -> None:
        total = len(self.components)
        self._log(f"\n{'='*50}")
        self._log(f"Installation Summary")
        self._log(f"  Successful: {completed}")
        self._log(f"  Failed: {failed}")
        self._log(f"  Total: {total}")
        if self.failed_components:
            self._log(f"Failed components:")
            for name, reason in self.failed_components[:10]:
                self._log(f"  - {name}: {reason}")
        self._log(f"Installation {'complete' if failed == 0 else 'finished with errors'}")

        async def auto_return():
            await asyncio.sleep(3)
            self.app.pop_screen()

        asyncio.create_task(auto_return())
