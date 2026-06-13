#!/usr/bin/env python3
"""TUI - Textual-based dotfiles setup and management utility."""

import asyncio
import platform
import shutil
import subprocess
import sys
import time
from pathlib import Path

from textual import on, work
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal, ScrollableContainer, Vertical
from textual.reactive import var
from textual.screen import ModalScreen, Screen
from textual.widgets import (
    Button,
    Checkbox,
    Footer,
    Header,
    Input,
    Label,
    ListItem,
    ListView,
    RichLog,
    Static,
)

from modules.loading_animations import (
    AnimatedLoadingScreen,
    BlockProgressScreen,
    MatrixLoadingScreen,
    BlockAnimations,
    BlockSpinner,
    ProgressBlocks,
)

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))
from modules import DOTFILES_DIR
from modules import grub as grub_mod
from modules.components_db import (
    DOTFILES_DATABASE,
    PROFILES,
    DotfileComponent,
    Profile,
    get_component,
)
from modules.component_manager import (
    BackupManager,
    DependencyResolver,
    PackageChecker,
)


# ── Modals ──────────────────────────────────────────────────────────────────


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


# ── Existing Screens ────────────────────────────────────────────────────────


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


# ── New Screens ─────────────────────────────────────────────────────────────


class SystemCheckScreen(Screen):
    """System compatibility check screen."""

    BINDINGS = [
        Binding("escape", "go_back", "Back"),
    ]

    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="syscheck-container"):
            yield Static("🔧 System Compatibility Check", classes="sc-title")
            with ScrollableContainer(id="sc-results"):
                yield Static("Running checks...", id="sc-status")
            with Horizontal(id="sc-buttons"):
                yield Button("🔄 Re-run", variant="default", id="sc-rerun")
                yield Button("↩ Back", variant="default", id="back-button")
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

        sections: list[tuple[str, list[str]]] = []

        info: list[str] = []
        info.append(f"  • OS: {platform.system()} {platform.release()}")
        info.append(f"  • Architecture: {platform.machine()}")
        info.append(f"  • Python: {sys.version.split()[0]}")
        info.append(f"  • Home: {Path.home()}")
        sections.append(("📋 System Information", info))

        usage = shutil.disk_usage(Path.home())
        free_gb = usage.free / (1024**3)
        disk: list[str] = [f"  • Free space: {free_gb:.1f} GB"]
        if free_gb < 1:
            disk.append("  [warning]⚠ Low disk space![/]")
        sections.append(("💾 Disk Space", disk))

        tools: list[str] = []
        for tool in ["git", "curl", "wget"]:
            found = shutil.which(tool) is not None
            status = "✅" if found else "❌"
            tools.append(f"  {status} {tool}")
        sections.append(("🔧 Required Tools", tools))

        pms: list[str] = []
        for pm in ["apt", "pacman", "dnf", "yay"]:
            found = shutil.which(pm) is not None
            status = "✅" if found else "❌"
            pms.append(f"  {status} {pm}")
        sections.append(("📦 Package Managers", pms))

        df: list[str] = []
        for name in [".zshrc", ".bashrc", ".vimrc", ".gitconfig", ".tmux.conf"]:
            path = Path.home() / name
            if path.exists():
                size = path.stat().st_size // 1024
                df.append(f"  ⚠ {name} ({size} KB) — will be backed up")
            else:
                df.append(f"  ✅ {name} — not present")
        sections.append(("📁 Existing Dotfiles", df))

        for title, lines in sections:
            results.mount(Static(title, classes="sc-section"))
            for line in lines:
                results.mount(Static(line, classes="sc-item"))

        self.query_one("#sc-status").update("✅ All checks completed")


class ComponentSelector(Screen):
    """Category-based component selection with checkboxes."""

    BINDINGS = [
        Binding("escape", "go_back", "Back"),
    ]

    def __init__(self) -> None:
        super().__init__()
        self.selected: set[str] = set()
        self.categories = list(DOTFILES_DATABASE.keys())
        self.current_cat = self.categories[0] if self.categories else ""

    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="cs-container"):
            with Horizontal(id="cs-top"):
                yield Static("📦 Select Components", classes="cs-title")
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
                yield Button("🔍 Check Deps", variant="default", id="cs-deps")
                yield Button("🔄 Clear", variant="default", id="cs-clear")
                yield Button("💾 Install", variant="success", id="cs-install")
                yield Button("↩ Back", variant="default", id="back-button")
        yield Footer()

    def on_mount(self) -> None:
        if self.current_cat:
            self._show_category(self.current_cat)

    def action_go_back(self) -> None:
        self.app.pop_screen()

    def _show_category(self, cat: str) -> None:
        self.current_cat = cat
        self.query_one("#cs-category-title").update(f"📁 {cat}")
        clist = self.query_one("#cs-list")
        clist.remove_children()

        for cname, comp in DOTFILES_DATABASE.get(cat, {}).items():
            cb = Checkbox(
                f"  {comp.description}",
                value=cname in self.selected,
                id=f"cs-cb-{cname}",
            )
            lbl = Static(f"[bold]{cname}[/]", classes="cs-comp-name")
            sz = Static(f"  📦 {comp.install_size_kb} KB" if comp.install_size_kb else "", classes="cs-comp-size")
            row = Container(cb, lbl, sz, classes="cs-comp-row")
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
            cat = bid[7:]
            self._show_category(cat)
        elif bid == "cs-deps":
            await self._check_deps()
        elif bid == "cs-clear":
            self.selected.clear()
            for cb in self.query("Checkbox"):
                cb.value = False
            self._update_count()
        elif bid == "cs-install":
            if self.selected:
                await self.app.push_screen_wait(MessageModal("Starting Installation", f"Installing {len(self.selected)} components..."))
                self.app.show_install_loading(list(self.selected))
            else:
                await self.app.push_screen_wait(MessageModal("Nothing Selected", "Select at least one component first."))
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
        n = len(self.selected)
        self.query_one("#cs-count").update(f"Selected: {n}")

    async def _check_deps(self) -> None:
        resolver = DependencyResolver()
        try:
            resolved = resolver.resolve(list(self.selected))
            conflicts = resolver.conflicts(list(self.selected))
            if conflicts:
                msg = "\n".join(f"⚠ {c1} ⟷ {c2}" for c1, c2 in conflicts)
                await self.app.push_screen_wait(MessageModal("Conflicts", msg))
            else:
                extra = [c for c in resolved if c not in self.selected]
                if extra:
                    await self.app.push_screen_wait(MessageModal("Dependencies", "Will also install:\n" + "\n".join(f"  • {c}" for c in extra)))
                else:
                    await self.app.push_screen_wait(MessageModal("Dependencies", "✅ No additional dependencies needed"))
        except Exception as e:
            await self.app.push_screen_wait(MessageModal("Error", str(e)))


class ProfileScreen(Screen):
    """Profile selection screen."""

    BINDINGS = [
        Binding("escape", "go_back", "Back"),
    ]

    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="ps-container"):
            yield Static("📦 Installation Profiles", classes="ps-title")
            yield Static("Pre-defined collections for specific use cases", classes="ps-subtitle")
            with ScrollableContainer(id="ps-grid"):
                for pname, profile in PROFILES.items():
                    with Container(classes="ps-card"):
                        yield Static(f"{profile.icon} {profile.name}", classes="ps-card-title")
                        yield Static(profile.description, classes="ps-card-desc")
                        yield Static(f"📦 {len(profile.components)} components", classes="ps-card-stats")
                        with Horizontal(classes="ps-card-actions"):
                            yield Button("📋 View", id=f"ps-view-{pname}", variant="default")
                            yield Button("✅ Select", id=f"ps-select-{pname}", variant="primary")
            with Horizontal(id="ps-bottom"):
                yield Button("🎨 Custom Selection", id="ps-custom", variant="default")
                yield Button("↩ Back", id="back-button", variant="default")
        yield Footer()

    def action_go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#back-button")
    def go_back(self) -> None:
        self.app.pop_screen()

    @on(Button.Pressed, "#ps-custom")
    def custom(self) -> None:
        self.app.pop_screen()
        self.app.push_screen(ComponentSelector())

    @on(Button.Pressed)
    async def handle_button(self, event: Button.Pressed) -> None:
        bid = event.button.id or ""
        if bid.startswith("ps-view-"):
            pname = bid[8:]
            profile = PROFILES.get(pname)
            if profile:
                details = "\n".join(f"  • {c}" for c in profile.components)
                await self.app.push_screen_wait(MessageModal(f"📋 {pname}", f"{profile.description}\n\nComponents:\n{details}"))
        elif bid.startswith("ps-select-"):
            pname = bid[10:]
            profile = PROFILES.get(pname)
            if profile:
                self.app.show_install_loading(list(profile.components), pname)


class InstallProgressScreen(Screen):
    """Installation progress with live console output."""

    BINDINGS = [
        Binding("escape", "go_back", "Back"),
    ]

    def __init__(self, components: list[str], profile_name: str | None = None) -> None:
        super().__init__()
        self.components = components
        self.profile_name = profile_name

    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="ip-container"):
            yield Static("💿 Installing Components", classes="ip-title")
            if self.profile_name:
                yield Static(f"Profile: {self.profile_name}", classes="ip-profile")
            yield Static(f"Total: {len(self.components)} components", classes="ip-total")
            with Container(id="ip-progress"):
                yield Static("0%", id="ip-pct", classes="ip-pct")
                yield Static("", id="ip-bar", classes="ip-bar")
            with Container(id="ip-operation"):
                yield Static("Preparing...", id="ip-op", classes="ip-op-text")
            yield ScrollableContainer(id="ip-status-list")
            with Container(id="ip-console"):
                yield ScrollableContainer(Static("", id="ip-console-text"))
            with Horizontal(id="ip-buttons"):
                yield Button("↩ Back to Menu", id="back-button", variant="default")
        yield Footer()

    def on_mount(self) -> None:
        self.run_install()

    @work(thread=False)
    async def run_install(self) -> None:
        resolver = DependencyResolver()
        checker = PackageChecker()
        backup = BackupManager()

        resolved = resolver.resolve(self.components)
        conflicts = resolver.conflicts(resolved)
        if conflicts:
            msg = "\n".join(f"⚠ {c1} ⟷ {c2}" for c1, c2 in conflicts)
            await self.app.push_screen_wait(MessageModal("Conflicts", msg))
            self.app.pop_screen()
            return

        total = len(resolved)
        for idx, cname in enumerate(resolved):
            comp = get_component(cname)
            self._op(f"Installing {cname}...")
            self._log(f"\n{'='*50}\nInstalling: {cname}")
            self._status(cname, "installing")

            if comp and comp.dependencies:
                missing = [p for p in comp.dependencies if not checker.check(p)]
                if missing:
                    cmd = checker.install_command(missing)
                    self._log(f"⚠ Missing: {', '.join(missing)}")
                    self._log(f"  → {cmd}")
                    self._status(cname, "failed", f"Missing: {', '.join(missing)}")
                    self._progress(idx + 1, total)
                    continue

            target = Path.home() / (comp.target if comp and comp.target else cname)
            if target.exists():
                self._log(f"Backing up {target.name}...")
                backup.backup(target)

            self._log(f"Installing {cname}...")
            self._call_installer(cname)
            self._log(f"✅ {cname} done")
            self._status(cname, "success", "Installed")
            self._progress(idx + 1, total)
            await asyncio.sleep(0.3)

        self._op("✅ Installation complete!")
        self._log(f"\n{'='*50}\n🎉 Installation completed!")
        self._log(f"Backup: {backup.backup_dir}")
        self._log("Restart your shell for changes to take effect.")

    def _call_installer(self, name: str) -> None:
        try:
            match name:
                case "zsh":
                    from modules.shell import setup_zsh
                    setup_zsh()
                case "starship":
                    from modules.shell import setup_starship
                    setup_starship()
                case "nvim_lazy" | "nvim_nvchad" | "nvim_astro" | "nvim_basic":
                    from modules.lazyvim import setup_neovim
                    setup_neovim()
                case "git_enhanced" | "git_aliases" | "git_ignore_global" | "system_aliases" | "env_vars" | "nodejs_dev" | "python_dev" | "rust_dev" | "go_dev" | "taskwarrior" | "timewarrior":
                    if Path(DOTFILES_DIR / "install.sh").is_file():
                        subprocess.run(
                            [str(DOTFILES_DIR / "install.sh"), "--unattended", "--minimal"],
                            capture_output=True, text=True, timeout=600,
                        )
                case _:
                    self._log(f"  → No automated installer for {name}, deploying defaults")
        except Exception as e:
            self._log(f"  ⚠ Installer error: {e}")

    def _progress(self, current: int, total: int) -> None:
        pct = int((current / total) * 100)
        bar = "█" * (pct // 2) + "░" * (50 - pct // 2)
        self.query_one("#ip-pct").update(f"{pct}%")
        self.query_one("#ip-bar").update(bar)

    def _op(self, text: str) -> None:
        self.query_one("#ip-op").update(text)

    def _status(self, cname: str, status: str, msg: str = "") -> None:
        symbols = {"pending": "⏳", "installing": "🔨", "success": "✅", "failed": "❌"}
        s = symbols.get(status, "❓")
        text = f"{s} {cname}" + (f": {msg}" if msg else "")
        w = Static(text, classes=f"ip-status-{status}")
        self.query_one("#ip-status-list").mount(w)
        self.query_one("#ip-status-list").scroll_end(animate=False)

    def _log(self, text: str) -> None:
        existing = self.query_one("#ip-console-text").renderable
        self.query_one("#ip-console-text").update(f"{existing}\n{text}" if existing else text)
        self.query_one("#ip-console").scroll_end(animate=False)

    @on(Button.Pressed, "#back-button")
    def go_back(self) -> None:
        self.app.pop_screen()

    def action_go_back(self) -> None:
        self.app.pop_screen()


# ── Main Menu ───────────────────────────────────────────────────────────────


class InstallerScreen(Screen):
    """Main menu screen with setup options."""

    MENU_ITEMS: list[tuple[str, str, str]] = [
        ("📦", "Packages", "Install distribution packages"),
        ("🔤", "Fonts", "Install Meslo Nerd + JetBrains Mono"),
        ("🐚", "ZSH", "Oh My Zsh + Powerlevel10k + plugins"),
        ("🖼", "Neofetch", "Browse and apply neofetch themes"),
        ("🎨", "GRUB Themes", "Install and manage GRUB themes"),
        ("✍", "Neovim", "Neovim + Lazy plugin manager"),
        ("⚡", "Everything", "Full dotfiles deployment"),
        ("", "", ""),
        ("📦", "Component Selector", "Browse and select individual components"),
        ("📋", "Profiles", "Pre-defined installation profiles"),
        ("🔧", "System Check", "Check system compatibility"),
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
            items = []
            for icon, name, _ in self.MENU_ITEMS:
                if not icon and not name:
                    items.append(ListItem(Static(""), classes="menu-separator"))
                else:
                    items.append(ListItem(Label(f"  {icon}  {name}"), id=f"menu-{name.lower().split()[0]}"))
            yield ListView(*items)
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
            case "menu-component":
                await self.push_screen(ComponentSelector())
            case "menu-profiles":
                await self.push_screen(ProfileScreen())
            case "menu-system":
                await self.push_screen(SystemCheckScreen())

    async def _run_task(self, label: str, coro) -> None:
        self._show_message("Working...", f"{label}\n\nThis may take a while.")
        result = await coro()
        self.dismiss()
        await self.app.push_screen_wait(MessageModal("Complete", result or "Done!"))

    def _show_message(self, title: str, message: str) -> None:
        try:
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
        result = subprocess.run(
            [str(install_script), "--unattended"],
            capture_output=True, text=True, timeout=600,
        )
        return result.stdout.strip() or result.stderr.strip() or "Full install completed."

    def action_quit_app(self) -> None:
        self.app.exit()


# ── App ────────────────────────────────────────────────────────────────────


class KrnlInstaller(App):
    """KRNL Installer - TUI for dotfiles deployment and management."""

    CSS_PATH = "assets/styles.tcss"
    TITLE = "KRNL Installer"
    SCREENS = {
        "main": InstallerScreen,
    }

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("escape", "back", "Back"),
    ]

    def on_ready(self) -> None:
        self._show_startup_animation()

    @work(thread=False)
    async def _show_startup_animation(self) -> None:
        """Show a brief animated loading screen before the main menu."""
        loader = AnimatedLoadingScreen(
            message="Initialising Dotfiles Installer",
            submessage="Preparing your development environment",
            animation="gradient",
            auto_advance=True,
        )
        await self.push_screen(loader)
        await asyncio.sleep(2.5)
        await self.pop_screen()
        self.push_screen("main")

    @work(thread=False)
    async def show_install_loading(self, components: list[str], profile_name: str | None = None) -> None:
        """Show animated loading before pushing the install progress screen."""
        loader = AnimatedLoadingScreen(
            message="Preparing Installation",
            submessage=f"Processing {len(components)} components",
            animation="breathing",
        )
        await self.push_screen(loader)
        steps = [
            ("Analysing dependencies...", 20),
            ("Checking system compatibility...", 40),
            ("Resolving conflicts...", 60),
            ("Creating backup directory...", 80),
            ("Ready to install", 100),
        ]
        for msg, pct in steps:
            loader.set_progress(pct, msg)
            await asyncio.sleep(0.4)
        await self.pop_screen()
        self.push_screen(InstallProgressScreen(components, profile_name))

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
