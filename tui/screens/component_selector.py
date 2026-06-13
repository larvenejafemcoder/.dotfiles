#!/usr/bin/env python3
"""Component selection screens - basic and distro-aware variants."""

import asyncio
from typing import Dict, List, Optional, Set, Tuple

from textual import on
from textual.binding import Binding
from textual.containers import Container, Horizontal, ScrollableContainer, Vertical
from textual.screen import Screen
from textual.widgets import Button, Checkbox, Input, Rule, Static, TabbedContent, TabPane

from modules.components_db import (
    DOTFILES_DATABASE,
    DotfileComponent,
    get_component,
    get_all_components,
)
from modules.component_manager import DependencyResolver
from tui.utils.distro_detector import DistroDetector, DistroFamily, DistroInfo
from tui.widgets.modals import ConfirmModal, MessageModal


class ComponentSelector(Screen):
    """Basic component selector (fallback if no distro info available)."""

    BINDINGS = [Binding("escape", "go_back", "Back")]

    def __init__(self) -> None:
        super().__init__()
        self.selected: Set[str] = set()
        self.categories = list(DOTFILES_DATABASE.keys())
        self.current_cat = self.categories[0] if self.categories else ""

    def compose(self) -> Container:
        yield Header()
        with Container(id="cs-container"):
            with Horizontal(id="cs-top"):
                yield Static("Select Components", classes="cs-title")
                yield Static("Selected: 0", id="cs-count")
            with Horizontal(id="cs-main"):
                with ScrollableContainer(id="cs-sidebar"):
                    yield Static("CATEGORIES", classes="cs-sidebar-header")
                    for cat in self.categories:
                        yield Button(cat, id=f"cs-cat-{cat}", classes="cs-cat-btn")
                with Vertical(id="cs-body"):
                    yield Static(id="cs-category-title", classes="cs-category-title")
                    yield ScrollableContainer(id="cs-list")
            with Horizontal(id="cs-actions"):
                yield Button("Check Deps", variant="default", id="cs-deps")
                yield Button("Clear", variant="default", id="cs-clear")
                yield Button("Install", variant="success", id="cs-install")
                yield Button("Back", variant="default", id="back-button")
        yield Footer()

    def on_mount(self) -> None:
        if self.current_cat:
            self._show_category(self.current_cat)

    def action_go_back(self) -> None:
        self.app.pop_screen()

    def _show_category(self, cat: str) -> None:
        self.current_cat = cat
        self.query_one("#cs-category-title").update(f"Category: {cat}")
        clist = self.query_one("#cs-list")
        clist.remove_children()
        for cname, comp in DOTFILES_DATABASE.get(cat, {}).items():
            size = f"  [{comp.install_size_kb} KB]" if comp.install_size_kb else ""
            cb = Checkbox(f"  {comp.description}", value=cname in self.selected, id=f"cs-cb-{cname}")
            lbl = Static(f"[bold]{cname}[/]{size}", classes="cs-comp-name")
            row = Container(cb, lbl, classes="cs-comp-row")
            clist.mount(row)
        for btn in self.query(".cs-cat-btn"):
            if btn.id == f"cs-cat-{cat}":
                btn.add_class("cs-active")
            else:
                btn.remove_class("cs-active")

    @on(Button.Pressed)
    async def handle_button(self, event: Button.Pressed) -> None:
        bid = event.button.id or ""
        if bid.startswith("cs-cat-"):
            self._show_category(bid[7:])
        elif bid == "cs-deps":
            await self._check_deps()
        elif bid == "cs-clear":
            self.selected.clear()
            for cb in self.query("Checkbox"):
                cb.value = False
            self._update_count()
        elif bid == "cs-install":
            if self.selected:
                self.app.show_install_loading(list(self.selected))
            else:
                await self.app.push_screen_wait(MessageModal("Nothing Selected", "Select at least one component.", 2))
        elif bid == "back-button":
            self.app.pop_screen()

    @on(Checkbox.Changed)
    def handle_checkbox(self, event: Checkbox.Changed) -> None:
        cbid = event.checkbox.id or ""
        if cbid.startswith("cs-cb-"):
            cname = cbid[6:]
            if event.value:
                self.selected.add(cname)
            else:
                self.selected.discard(cname)
            self._update_count()

    def _update_count(self) -> None:
        self.query_one("#cs-count").update(f"Selected: {len(self.selected)}")

    async def _check_deps(self) -> None:
        resolver = DependencyResolver()
        try:
            resolved = resolver.resolve(list(self.selected))
            conflicts = resolver.conflicts(list(self.selected))
            if conflicts:
                msg = "\n".join(f"! {c1} <-> {c2}" for c1, c2 in conflicts)
                await self.app.push_screen_wait(MessageModal("Conflicts", msg))
            else:
                extra = [c for c in resolved if c not in self.selected]
                if extra:
                    await self.app.push_screen_wait(MessageModal("Dependencies", "Will also install:\n" + "\n".join(f"  - {c}" for c in extra)))
                else:
                    await self.app.push_screen_wait(MessageModal("Dependencies", "No additional dependencies needed", 2))
        except Exception as e:
            await self.app.push_screen_wait(MessageModal("Error", str(e)))


class DistroInfoScreen(Screen):
    """Screen showing detected distribution information."""

    BINDINGS = [Binding("escape", "go_back", "Back")]

    def __init__(self, distro: DistroInfo) -> None:
        super().__init__()
        self.distro = distro

    def compose(self) -> Container:
        yield Header()
        with Container(id="distro-container"):
            yield Static("System Information", id="title-text")

            with Container(id="distro-card"):
                yield Static("Detected Distribution", classes="distro-section-title")
                with Container(id="distro-info-grid"):
                    yield Static("Name:", classes="distro-label")
                    yield Static(f"[bold]{self.distro.name.capitalize()}[/]", classes="distro-value")
                    yield Static("Family:", classes="distro-label")
                    yield Static(f"{self.distro.family.value.upper()}", classes="distro-value")
                    yield Static("Version:", classes="distro-label")
                    yield Static(f"{self.distro.version or self.distro.version_id or 'Unknown'}", classes="distro-value")
                    yield Static("Codename:", classes="distro-label")
                    yield Static(f"{self.distro.codename or 'N/A'}", classes="distro-value")
                    yield Static("Package Manager:", classes="distro-label")
                    yield Static(f"{self.distro.package_manager.upper()}", classes="distro-value")
                    if self.distro.aur_helper:
                        yield Static("AUR Helper:", classes="distro-label")
                        yield Static(f"{self.distro.aur_helper}", classes="distro-value")
                    yield Static("Flatpak:", classes="distro-label")
                    yield Static("Available" if self.distro.flatpak_available else "Not installed", classes="distro-value")

            yield Rule()

            with Container(id="distro-recommendations"):
                yield Static("Distribution-Specific Recommendations", classes="distro-section-title")
                for rec in self._get_recommendations():
                    yield Static(f"  - {rec}", classes="recommendation-item")

            yield Rule()

            with Horizontal(id="distro-actions"):
                yield Button("Continue to Component Selection", id="continue-btn", variant="primary")
                yield Button("Re-detect", id="redetect-btn", variant="default")
                yield Button("Back", id="back-button", variant="default")

        yield Footer()

    def _get_recommendations(self) -> List[str]:
        recs = []
        if self.distro.is_arch_based:
            recs.append("Arch detected: AUR helper available for additional packages")
            if not self.distro.aur_helper:
                recs.append("  -> Install yay or paru for better AUR support")
        elif self.distro.is_debian_based:
            recs.append("Debian/Ubuntu detected: Enable universe/multiverse repos for more packages")
        elif self.distro.is_redhat_based:
            recs.append("Fedora/RHEL detected: Enable RPM Fusion for additional packages")

        if not self.distro.flatpak_available:
            recs.append("Flatpak not detected: Install for better app availability")

        if not recs:
            recs.append("No specific recommendations for this distribution")
        return recs

    @on(Button.Pressed, "#continue-btn")
    def continue_selection(self) -> None:
        self.app.pop_screen()
        self.app.push_screen(DistroAwareComponentSelector(self.distro))

    @on(Button.Pressed, "#redetect-btn")
    async def redetect(self) -> None:
        self.distro = DistroDetector.detect()
        await self.recompose()

    @on(Button.Pressed, "#back-button")
    def go_back(self) -> None:
        self.app.pop_screen()

    def action_go_back(self) -> None:
        self.app.pop_screen()


class DistroAwareComponentSelector(Screen):
    """Component selector with distro-aware filtering and recommendations."""

    BINDINGS = [
        Binding("escape", "go_back", "Back"),
        Binding("ctrl+f", "focus_search", "Search"),
        Binding("/", "focus_search", "Search"),
        Binding("a", "select_all", "Select All"),
        Binding("n", "select_none", "Select None"),
        Binding("space", "toggle_current", "Toggle"),
        Binding("d", "show_distro_info", "Distro Info"),
    ]

    def __init__(self, distro: DistroInfo) -> None:
        super().__init__()
        self.distro = distro
        self.selected: Set[str] = set()
        self.categories = list(DOTFILES_DATABASE.keys())
        self.current_cat = self.categories[0] if self.categories else ""
        self.filter_text = ""
        self.filtered_components: Dict[str, DotfileComponent] = {}
        self.component_availability: Dict[str, Tuple[bool, str]] = {}

        for cat in self.categories:
            for cname in DOTFILES_DATABASE.get(cat, {}):
                self.component_availability[cname] = DistroDetector.get_component_availability(distro, cname)

    def compose(self) -> Container:
        yield Header()
        with Container(id="cs-container"):
            with Horizontal(id="cs-top"):
                yield Static("Distro-Aware Component Selector", classes="cs-title")
                yield Static(f"{self.distro.name.capitalize()}", id="cs-distro-badge", classes="cs-badge")
                yield Static("Selected: 0", id="cs-count")
                yield Static(f"Total: {len(get_all_components())}", id="cs-total")

            with Horizontal(id="cs-search-bar"):
                yield Input(placeholder="Filter components...", id="cs-search", classes="cs-search-input")
                yield Button("Clear", id="cs-clear-search", variant="default")
                yield Button("Show Distro Info", id="cs-distro-info", variant="default")

            with Horizontal(id="cs-main"):
                with ScrollableContainer(id="cs-sidebar"):
                    yield Static("CATEGORIES", classes="cs-sidebar-header")
                    for cat in self.categories:
                        count = len(DOTFILES_DATABASE.get(cat, {}))
                        yield Button(f"{cat} ({count})", id=f"cs-cat-{cat}", classes="cs-cat-btn")

                with Vertical(id="cs-body"):
                    yield Static(id="cs-category-title", classes="cs-category-title")
                    with TabbedContent(id="cs-tabs"):
                        with TabPane("Components", id="tab-components"):
                            yield ScrollableContainer(id="cs-list")
                        with TabPane("Selected", id="tab-selected"):
                            yield ScrollableContainer(id="cs-selected-list")
                        with TabPane("Conflicts", id="tab-conflicts"):
                            yield ScrollableContainer(id="cs-conflicts-list")
                        with TabPane("Distro Info", id="tab-distro"):
                            yield ScrollableContainer(id="cs-distro-info-pane")

            with Horizontal(id="cs-actions"):
                yield Button("Check Dependencies", variant="default", id="cs-deps")
                yield Button("Estimate Size", variant="default", id="cs-size")
                yield Button("Select Recommended", variant="default", id="cs-recommended")
                yield Button("Select Available", variant="default", id="cs-available")
                yield Button("Clear All", variant="default", id="cs-clear-all")
                yield Button("Install Selected", variant="success", id="cs-install")
                yield Button("Back", variant="default", id="back-button")

        yield Footer()

    def on_mount(self) -> None:
        self._update_distro_info_tab()
        if self.current_cat:
            self._show_category(self.current_cat)
        self._update_selected_view()
        self._update_count()

    def _update_distro_info_tab(self) -> None:
        info_pane = self.query_one("#cs-distro-info-pane")
        info_pane.remove_children()
        info_pane.mount(Static(f"[bold]Distribution:[/] {self.distro.name.capitalize()}", classes="distro-info-line"))
        info_pane.mount(Static(f"[bold]Family:[/] {self.distro.family.value.upper()}", classes="distro-info-line"))
        info_pane.mount(Static(f"[bold]Version:[/] {self.distro.version or self.distro.version_id or 'Unknown'}", classes="distro-info-line"))
        info_pane.mount(Static(f"[bold]Package Manager:[/] {self.distro.package_manager.upper()}", classes="distro-info-line"))
        info_pane.mount(Static(f"[bold]Install command:[/] {self.distro.package_manager_cmd}", classes="distro-info-line"))
        if self.distro.aur_helper:
            info_pane.mount(Static(f"[bold]AUR Helper:[/] {self.distro.aur_helper}", classes="distro-info-line"))
        info_pane.mount(Static("", classes="distro-spacer"))
        info_pane.mount(Static("[bold]Component Availability Notes:[/]", classes="distro-info-line"))
        for comp in ["docker", "kvm", "hyprland", "nvidia_drivers"]:
            _, note = self.component_availability.get(comp, (True, "Unknown"))
            if "Not available" in note:
                status = "Unavailable"
            else:
                status = "Available"
            info_pane.mount(Static(f"  {status}: {comp} ({note[:60]})", classes="distro-avail-line"))

    def action_go_back(self) -> None:
        self.app.pop_screen()

    def action_focus_search(self) -> None:
        self.query_one("#cs-search", Input).focus()

    def action_show_distro_info(self) -> None:
        info_text = (f"Distribution: {self.distro.name.capitalize()}\n"
                     f"Family: {self.distro.family.value.upper()}\n"
                     f"Version: {self.distro.version or self.distro.version_id or 'Unknown'}\n"
                     f"Package Manager: {self.distro.package_manager.upper()}\n"
                     f"Flatpak: {'Yes' if self.distro.flatpak_available else 'No'}")
        asyncio.create_task(
            self.app.push_screen_wait(MessageModal("Distribution Info", info_text, 5))
        )

    def action_select_all(self) -> None:
        for comp in self.filtered_components.values():
            self.selected.add(comp.name)
        self._refresh_current_category()
        self._update_selected_view()
        self._update_count()

    def action_select_none(self) -> None:
        self.selected.clear()
        self._refresh_current_category()
        self._update_selected_view()
        self._update_count()

    def action_toggle_current(self) -> None:
        focused = self.focused
        if focused and hasattr(focused, "id") and focused.id and focused.id.startswith("cs-cb-"):
            cname = focused.id[6:]
            checkbox = self.query_one(f"#cs-cb-{cname}", Checkbox)
            checkbox.value = not checkbox.value

    def _refresh_current_category(self) -> None:
        if self.current_cat:
            self._show_category(self.current_cat)

    def _show_category(self, cat: str) -> None:
        self.current_cat = cat
        self.query_one("#cs-category-title").update(f"Category: {cat}")

        components = DOTFILES_DATABASE.get(cat, {})
        self.filtered_components = {
            name: comp for name, comp in components.items()
            if not self.filter_text
            or self.filter_text.lower() in name.lower()
            or self.filter_text.lower() in comp.description.lower()
        }

        clist = self.query_one("#cs-list")
        clist.remove_children()

        for cname, comp in sorted(self.filtered_components.items()):
            available, avail_note = self.component_availability.get(cname, (True, "Available"))
            is_unavailable = "Not available" in avail_note

            size = f"  [{comp.install_size_kb/1024:.1f} MB]" if comp.install_size_kb else ""
            deps = f"  [{len(comp.dependencies)} dep(s)]" if comp.dependencies else ""
            status = "[x]" if cname in self.selected else "[ ]"
            warning = " [!]" if is_unavailable else ""

            cb = Checkbox(
                value=cname in self.selected,
                id=f"cs-cb-{cname}",
                classes="cs-comp-checkbox",
                disabled=is_unavailable,
            )
            label = Static(f"{status} {cname}{size}{deps}{warning}", classes="cs-comp-name")
            desc = Static(f"  {comp.description[:70]}", classes="cs-comp-desc")
            row = Container(cb, Container(label, desc, classes="cs-comp-info"), classes="cs-comp-row")
            clist.mount(row)

        for btn in self.query(".cs-cat-btn"):
            bid = btn.id or ""
            if bid == f"cs-cat-{cat}":
                btn.add_class("cs-active")
            else:
                btn.remove_class("cs-active")

    def _update_selected_view(self) -> None:
        selected_list = self.query_one("#cs-selected-list")
        selected_list.remove_children()

        if not self.selected:
            selected_list.mount(Static("No components selected", classes="cs-empty"))
            return

        selected_by_cat: Dict[str, List[str]] = {}
        for cname in sorted(self.selected):
            for cat, comps in DOTFILES_DATABASE.items():
                if cname in comps:
                    selected_by_cat.setdefault(cat, []).append(cname)
                    break

        for cat, comps in selected_by_cat.items():
            selected_list.mount(Static(f"[bold]{cat}[/]", classes="cs-selected-cat"))
            for cname in comps:
                sz = ""
                comp = get_component(cname)
                if comp and comp.install_size_kb:
                    sz = f"  ({comp.install_size_kb/1024:.1f} MB)"
                _, note = self.component_availability.get(cname, (True, ""))
                warning = " [!]" if "Not available" in note else ""
                selected_list.mount(Static(f"  {cname}{sz}{warning}", classes="cs-selected-item"))

    def _update_conflicts_view(self, conflicts: List[Tuple[str, str]]) -> None:
        conflicts_list = self.query_one("#cs-conflicts-list")
        conflicts_list.remove_children()
        if not conflicts:
            conflicts_list.mount(Static("No conflicts detected", classes="cs-empty"))
            return
        for c1, c2 in conflicts:
            conflicts_list.mount(Static(f"! {c1} conflicts with {c2}", classes="cs-conflict-item"))

    @on(Button.Pressed)
    async def handle_button(self, event: Button.Pressed) -> None:
        bid = event.button.id or ""

        if bid.startswith("cs-cat-"):
            cat_full = bid[7:]
            if "(" in cat_full:
                cat = cat_full.split("(")[0].strip()
            else:
                cat = cat_full
            self._show_category(cat)

        elif bid == "cs-deps":
            await self._check_deps()
        elif bid == "cs-size":
            await self._estimate_size()
        elif bid == "cs-recommended":
            await self._select_recommended()
        elif bid == "cs-available":
            self._select_available_only()
        elif bid == "cs-clear-all":
            self.action_select_none()
        elif bid == "cs-clear-search":
            self.filter_text = ""
            self.query_one("#cs-search", Input).value = ""
            self._refresh_current_category()
        elif bid == "cs-distro-info":
            self.action_show_distro_info()
        elif bid == "cs-install":
            if self.selected:
                await self._confirm_installation()
            else:
                await self.app.push_screen_wait(MessageModal("Nothing Selected", "Select at least one component.", 2))
        elif bid == "back-button":
            self.app.pop_screen()

    @on(Checkbox.Changed)
    def handle_checkbox(self, event: Checkbox.Changed) -> None:
        cb_id = event.checkbox.id or ""
        if cb_id.startswith("cs-cb-"):
            cname = cb_id[6:]
            if event.value:
                self.selected.add(cname)
            else:
                self.selected.discard(cname)
            self._update_count()
            self._update_selected_view()
        elif cb_id.startswith("cs-sel-"):
            cname = cb_id[7:]
            if not event.value:
                self.selected.discard(cname)
            self._update_count()
            self._update_selected_view()

    @on(Input.Changed, "#cs-search")
    def handle_search(self, event: Input.Changed) -> None:
        self.filter_text = event.value
        self._refresh_current_category()

    def _update_count(self) -> None:
        n = len(self.selected)
        self.query_one("#cs-count").update(f"Selected: {n}")
        install_btn = self.query_one("#cs-install", Button)
        if install_btn:
            install_btn.label = f"Install Selected ({n})"

    def _select_available_only(self) -> None:
        newly = set()
        for cat, comps in DOTFILES_DATABASE.items():
            for cname in comps:
                available, note = self.component_availability.get(cname, (True, ""))
                if available and "Not available" not in note:
                    newly.add(cname)
        self.selected = newly
        self._refresh_current_category()
        self._update_selected_view()
        self._update_count()

    async def _select_recommended(self) -> None:
        recommended = {
            DistroFamily.ARCH: ["zsh", "starship", "git_enhanced", "neovim", "docker", "kvm"],
            DistroFamily.UBUNTU: ["zsh", "starship", "git_enhanced", "neovim", "docker"],
            DistroFamily.DEBIAN: ["zsh", "starship", "git_enhanced", "neovim"],
            DistroFamily.FEDORA: ["zsh", "starship", "git_enhanced", "neovim", "docker"],
        }
        rec_list = recommended.get(self.distro.family, ["zsh", "starship", "git_enhanced"])
        available_recs = []
        for rec in rec_list:
            available, note = self.component_availability.get(rec, (True, ""))
            if available and "Not available" not in note:
                available_recs.append(rec)
        self.selected = set(available_recs)
        msg = f"Selected {len(available_recs)} recommended components for {self.distro.name}" if available_recs else "No recommended components available"
        await self.app.push_screen_wait(MessageModal("Recommended", msg, 2))
        self._refresh_current_category()
        self._update_selected_view()
        self._update_count()

    async def _check_deps(self) -> None:
        resolver = DependencyResolver()
        if not self.selected:
            await self.app.push_screen_wait(MessageModal("No Selection", "Select components first.", 2))
            return
        try:
            resolved = resolver.resolve(list(self.selected))
            conflicts = resolver.conflicts(list(self.selected))
            self._update_conflicts_view(conflicts)
            if conflicts:
                msg = "\n".join(f"! {c1} <-> {c2}" for c1, c2 in conflicts[:10])
                await self.app.push_screen_wait(MessageModal("Conflicts Detected", f"Found {len(conflicts)} conflicts:\n{msg}"))
            else:
                extra = [c for c in resolved if c not in self.selected]
                if extra:
                    await self.app.push_screen_wait(MessageModal("Dependencies Required", f"Will also install {len(extra)} dependencies:\n" + "\n".join(f"  - {c}" for c in extra[:20])))
                else:
                    await self.app.push_screen_wait(MessageModal("Dependencies", "No additional dependencies needed", 2))
        except Exception as e:
            await self.app.push_screen_wait(MessageModal("Error", f"Failed: {e}"))

    async def _estimate_size(self) -> None:
        total_kb = 0
        for cname in self.selected:
            comp = get_component(cname)
            if comp and comp.install_size_kb:
                total_kb += comp.install_size_kb
        if total_kb > 0:
            if total_kb >= 1024 * 1024:
                sz = f"{total_kb / 1024 / 1024:.2f} GB"
            elif total_kb >= 1024:
                sz = f"{total_kb / 1024:.2f} MB"
            else:
                sz = f"{total_kb:.0f} KB"
            await self.app.push_screen_wait(MessageModal("Size Estimate", f"Selected components: {sz}"))
        else:
            await self.app.push_screen_wait(MessageModal("Size Estimate", "No size info available.", 2))

    async def _confirm_installation(self) -> None:
        unavailable = []
        for cname in self.selected:
            _, note = self.component_availability.get(cname, (True, ""))
            if "Not available" in note:
                unavailable.append(cname)

        warning = ""
        if unavailable:
            warning = f"\n\nWarning: {len(unavailable)} component(s) may have limited support on {self.distro.name}\n"
            for u in unavailable[:5]:
                warning += f"  - {u}\n"

        summary = f"Components: {len(self.selected)}\n{warning}\n"
        cat_summary: Dict[str, List[str]] = {}
        for cname in sorted(self.selected):
            for cat, comps in DOTFILES_DATABASE.items():
                if cname in comps:
                    cat_summary.setdefault(cat, []).append(cname)
                    break
        for cat, comps in list(cat_summary.items())[:5]:
            summary += f"  {cat}:\n"
            for c in comps[:5]:
                summary += f"    - {c}\n"
            if len(comps) > 5:
                summary += f"    ... and {len(comps) - 5} more\n"

        confirmed = await self.app.push_screen_wait(
            ConfirmModal("Confirm Installation", summary[:600], "Install Now", "Cancel", danger=bool(unavailable))
        )
        if confirmed:
            self.app.show_install_loading(list(self.selected), distro=self.distro)
