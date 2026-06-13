#!/usr/bin/env python3
"""System compatibility check screen."""

import platform
import shutil
import sys
from pathlib import Path
from typing import List, Tuple

from textual import on
from textual.binding import Binding
from textual.containers import Container, Horizontal, ScrollableContainer
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, Static


class SystemCheckScreen(Screen):
    BINDINGS = [Binding("escape", "go_back", "Back")]

    def compose(self) -> Container:
        yield Header()
        with Container(id="syscheck-container"):
            yield Static("System Compatibility Check", classes="sc-title")
            with ScrollableContainer(id="sc-results"):
                yield Static("Running checks...", id="sc-status")
            with Horizontal(id="sc-buttons"):
                yield Button("Re-run", variant="default", id="sc-rerun")
                yield Button("Back", variant="default", id="back-button")
        yield Footer()

    def on_mount(self) -> None:
        self.run_checks()

    def action_go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#back-button")
    def go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#sc-rerun")
    def rerun(self) -> None:
        self.run_checks()

    def run_checks(self) -> None:
        results = self.query_one("#sc-results")
        results.remove_children()

        sections: List[Tuple[str, List[str]]] = []

        info = [
            f"  - OS: {platform.system()} {platform.release()}",
            f"  - Architecture: {platform.machine()}",
            f"  - Python: {sys.version.split()[0]}",
            f"  - Home: {Path.home()}",
        ]
        sections.append(("System Information", info))

        usage = shutil.disk_usage(Path.home())
        free_gb = usage.free / (1024**3)
        disk = [f"  - Free space: {free_gb:.1f} GB"]
        if free_gb < 1:
            disk.append("  [warning]! Low disk space![/]")
        sections.append(("Disk Space", disk))

        tools = []
        for tool in ["git", "curl", "wget"]:
            found = shutil.which(tool) is not None
            tools.append(f"  {'OK' if found else 'MISSING':>7} {tool}")
        sections.append(("Required Tools", tools))

        pms = []
        for pm in ["apt", "pacman", "dnf", "yay"]:
            found = shutil.which(pm) is not None
            pms.append(f"  {'OK' if found else 'MISSING':>7} {pm}")
        sections.append(("Package Managers", pms))

        df = []
        for name in [".zshrc", ".bashrc", ".vimrc", ".gitconfig", ".tmux.conf"]:
            path = Path.home() / name
            if path.exists():
                size = path.stat().st_size // 1024
                df.append(f"  * {name} ({size} KB) - will be backed up")
            else:
                df.append(f"  - {name} - not present")
        sections.append(("Existing Dotfiles", df))

        for title, lines in sections:
            results.mount(Static(f"--- {title} ---", classes="sc-section"))
            for line in lines:
                results.mount(Static(line, classes="sc-item"))

        self.query_one("#sc-status").update("All checks completed")
