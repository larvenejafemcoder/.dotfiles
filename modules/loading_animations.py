"""Loading animation screens and widgets for the TUI."""

import asyncio
import random
import time
from datetime import datetime
from itertools import cycle
from typing import Any, Generator, Optional

from textual import on, work
from textual.app import ComposeResult
from textual.containers import Center, Container, Horizontal, ScrollableContainer, Vertical
from textual.screen import Screen
from textual.timer import Timer
from textual.widgets import Button, Footer, Header, Label, ProgressBar, Static


# ── Block Animation Generators ──────────────────────────────────────────────


class BlockAnimations:
    """Generator-based block animation frames."""

    @staticmethod
    def bouncing() -> Generator[str, None, None]:
        frames = [
            "█░░░░░░░", "██░░░░░░", "███░░░░░", "████░░░░",
            "█████░░░", "██████░░", "███████░", "████████",
            "███████░", "██████░░", "█████░░░", "████░░░░",
            "███░░░░░", "██░░░░░░", "█░░░░░░░", "░░░░░░░░",
        ]
        yield from cycle(f"[green]{f}[/green]" for f in frames)

    @staticmethod
    def pulse() -> Generator[str, None, None]:
        while True:
            for size in range(1, 9):
                b = "█" * size
                s = "░" * (8 - size)
                yield f"[green]{b}[/green][white]{s}[/white]"
                time.sleep(0.05)
            for size in range(7, 0, -1):
                b = "█" * size
                s = "░" * (8 - size)
                yield f"[green]{b}[/green][white]{s}[/white]"
                time.sleep(0.05)

    @staticmethod
    def wave() -> Generator[str, None, None]:
        while True:
            for pos in range(10):
                line = ["░"] * 20
                for i in range(3):
                    if pos + i < 20:
                        line[pos + i] = "█"
                yield f"[cyan]{''.join(line)}[/cyan]"
                time.sleep(0.03)
            for pos in range(8, -1, -1):
                line = ["░"] * 20
                for i in range(3):
                    if pos + i < 20:
                        line[pos + i] = "█"
                yield f"[cyan]{''.join(line)}[/cyan]"
                time.sleep(0.03)

    @staticmethod
    def snake() -> Generator[str, None, None]:
        snake = [(0, 0)]
        direction = 1
        while True:
            line = ["░"] * 30
            for i, pos in enumerate(snake):
                if 0 <= pos[0] < 30:
                    line[pos[0]] = "█" if i == 0 else "▓"
            head = snake[0][0] + direction
            snake.insert(0, (head, 0))
            snake.pop()
            if head >= 29 or head <= 0:
                direction *= -1
            yield f"[green]{''.join(line)}[/green]"
            time.sleep(0.05)

    @staticmethod
    def gradient() -> Generator[str, None, None]:
        colors = cycle(["red", "yellow", "green", "cyan", "blue", "magenta"])
        while True:
            color = next(colors)
            yield f"[{color}]{'█' * 40}[/{color}]"
            time.sleep(0.1)

    @staticmethod
    def breathing() -> Generator[str, None, None]:
        while True:
            for size in range(10, 31, 2):
                yield f"[green]{'█' * size}[/green][white]{'░' * (30 - size)}[/white]"
                time.sleep(0.03)
            for size in range(28, 9, -2):
                yield f"[green]{'█' * size}[/green][white]{'░' * (30 - size)}[/white]"
                time.sleep(0.03)

    @staticmethod
    def glitch() -> Generator[str, None, None]:
        chars = ["█", "▓", "▒", "░"]
        colors = cycle(["green", "red", "yellow", "cyan"])
        while True:
            line = "".join(random.choice(chars) for _ in range(40))
            yield f"[{next(colors)}]{line}[/{next(colors)}]"
            time.sleep(0.03)

    @staticmethod
    def mosaic() -> Generator[str, None, None]:
        patterns = cycle([
            "█░█░█░█░█░█░", "░█░█░█░█░█░█",
            "██░░██░░██░░", "░░██░░██░░██",
            "███░░░███░░░", "░░░███░░░███",
        ])
        while True:
            yield f"[cyan]{next(patterns) * 3}[/cyan]"
            time.sleep(0.15)


ANIMATIONS: dict[str, Any] = {
    "bouncing": BlockAnimations.bouncing,
    "pulse": BlockAnimations.pulse,
    "wave": BlockAnimations.wave,
    "snake": BlockAnimations.snake,
    "gradient": BlockAnimations.gradient,
    "breathing": BlockAnimations.breathing,
    "glitch": BlockAnimations.glitch,
    "mosaic": BlockAnimations.mosaic,
}


# ── Animated Loading Screen ─────────────────────────────────────────────────


class AnimatedLoadingScreen(Screen):
    """Loading screen with block-style animations."""

    def __init__(
        self,
        message: str = "Loading...",
        submessage: str = "",
        animation: str = "bouncing",
        total: int = 100,
        auto_advance: bool = False,
    ) -> None:
        super().__init__()
        self._message = message
        self._submessage = submessage
        self._animation = animation
        self._total = total
        self._step = 0
        self._auto = auto_advance
        self._gen: Optional[Generator] = None
        self._anim_timer: Optional[Timer] = None

    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="loading-container"):
            with Container(classes="loading-panel"):
                yield Static("", id="ld-title", classes="ld-title")
                with Center(id="ld-anim-center"):
                    yield Static("", id="ld-anim", classes="ld-anim")
                yield Static(self._message, id="ld-msg", classes="ld-msg")
                if self._submessage:
                    yield Static(self._submessage, id="ld-sub", classes="ld-sub")
                yield ProgressBar(total=self._total, show_percentage=True, id="ld-progress")
                yield Static("", id="ld-pct-text", classes="ld-pct-text")
                with Horizontal(classes="ld-dots"):
                    for i in range(3):
                        yield Static("", id=f"ld-dot-{i}", classes="ld-dot")
        yield Footer()

    def on_mount(self) -> None:
        self._start_anim()
        self._start_dots()
        if self._auto:
            self._start_auto()

    def _start_anim(self) -> None:
        factory = ANIMATIONS.get(self._animation, BlockAnimations.bouncing)
        self._gen = factory()

        def tick() -> None:
            try:
                self.query_one("#ld-anim").update(next(self._gen))
            except StopIteration:
                self._gen = factory()
        self._anim_timer = self.set_interval(0.05, tick)

    def _start_dots(self) -> None:
        states = ["⚫", "🔴", "🟡", "🟢", "🔵", "🟣"]
        idx = 0
        def tick() -> None:
            nonlocal idx
            for i in range(3):
                c = states[(idx + i) % len(states)]
                self.query_one(f"#ld-dot-{i}").update(c)
            idx = (idx + 1) % len(states)
        self.set_interval(0.3, tick)

    def _start_auto(self) -> None:
        def tick() -> None:
            if self._step < self._total:
                self._step += 1
                self.set_progress(self._step)
        self.set_interval(0.05, tick)

    def set_progress(self, step: int, message: Optional[str] = None) -> None:
        self._step = min(step, self._total)
        bar = self.query_one("#ld-progress", ProgressBar)
        bar.progress = self._step
        pct = int((self._step / self._total) * 100)
        self.query_one("#ld-pct-text").update(f"{pct}%")
        if message:
            self.query_one("#ld-msg").update(message)

    def set_message(self, msg: str, sub: str = "") -> None:
        self.query_one("#ld-msg").update(msg)
        if sub:
            self.query_one("#ld-sub").update(sub)


# ── Block Progress Grid Screen ──────────────────────────────────────────────


class BlockProgressScreen(Screen):
    """Installation progress with block-grid visualization."""

    def __init__(self, total: int, title: str = "Installation Progress") -> None:
        super().__init__()
        self._total = total
        self._title = title
        self._completed: list[int] = []
        self._grid: list[list[Static]] = []
        self._start_time: float = 0.0

    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="bp-container"):
            yield Static(self._title, classes="bp-title")
            with Container(id="bp-grid", classes="bp-grid"):
                pass
            with Container(classes="bp-current"):
                yield Static("🔨 CURRENT", classes="bp-current-title")
                yield Static("", id="bp-op-text", classes="bp-op-text")
            with Container(classes="bp-log"):
                yield Static("📋 LOG", classes="bp-log-title")
                yield ScrollableContainer(Static("", id="bp-log-text"), classes="bp-log-scroll")
            with Horizontal(classes="bp-status"):
                yield Static("", id="bp-status-text")
                yield Static("", id="bp-time")
        yield Footer()

    def on_mount(self) -> None:
        self._build_grid()
        self._start_time = time.time()
        self.set_interval(1, self._tick_time)

    def _build_grid(self) -> None:
        grid = self.query_one("#bp-grid")
        cols = min(10, self._total)
        rows = (self._total + cols - 1) // cols
        self._grid = [[None for _ in range(cols)] for _ in range(rows)]

        for i in range(self._total):
            r, c = divmod(i, cols)
            block = Static("░", id=f"bp-b-{i}", classes="bp-block")
            block.styles.width = 3
            grid.mount(block)
            self._grid[r][c] = block

        grid.styles.grid_size = (cols, rows)
        grid.styles.grid_gutter = (1, 1)

    def set_block(self, index: int, status: str) -> None:
        if index >= self._total:
            return
        chars = {"pending": "░", "installing": "▓", "success": "█", "failed": "✗", "skipped": "○"}
        colors = {"pending": "white", "installing": "yellow", "success": "green", "failed": "red", "skipped": "blue"}
        for row in self._grid:
            for col_index, block in enumerate(row):
                block_index = self._grid.index(row) * len(row) + col_index
                if block_index == index:
                    block.update(chars.get(status, "░"))
                    block.styles.color = colors.get(status, "white")
                    return

    def set_op(self, text: str) -> None:
        self.query_one("#bp-op-text").update(text)

    def log(self, text: str, kind: str = "info") -> None:
        symbols = {"info": "ℹ️", "success": "✅", "error": "❌", "warning": "⚠️", "install": "📦"}
        ts = datetime.now().strftime("%H:%M:%S")
        entry = f"{symbols.get(kind, '•')} [{ts}] {text}"
        existing = self.query_one("#bp-log-text").renderable
        self.query_one("#bp-log-text").update(f"{existing}\n{entry}" if existing else entry)
        self.query_one("#bp-log-scroll").scroll_end(animate=False)

    def mark_done(self, index: int, ok: bool = True) -> bool:
        self.set_block(index, "success" if ok else "failed")
        self._completed.append(index)
        n = len(self._completed)
        pct = int((n / self._total) * 100)
        self.query_one("#bp-status-text").update(f"{n}/{self._total} ({pct}%)")
        return n == self._total

    def _tick_time(self) -> None:
        elapsed = int(time.time() - self._start_time)
        self.query_one("#bp-time").update(f"⏱ {elapsed // 60:02d}:{elapsed % 60:02d}")


# ── Matrix-Style Loading Screen ─────────────────────────────────────────────


class MatrixLoadingScreen(Screen):
    """Matrix digital-rain loading screen."""

    def __init__(self, message: str = "Initialising...") -> None:
        super().__init__()
        self._message = message
        self._rain_timer: Optional[Timer] = None
        self._progress_timer: Optional[Timer] = None

    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="mx-container"):
            yield Static("", id="mx-bar", classes="mx-bar")
            yield Static(self._message, id="mx-msg", classes="mx-msg")
            yield Container(id="mx-rain", classes="mx-rain")
            with Container(classes="mx-stats"):
                yield Static("", id="mx-status")
                yield Static("", id="mx-progress")
        yield Footer()

    def on_mount(self) -> None:
        self._start_rain()
        self._start_progress()

    def _start_rain(self) -> None:
        columns: list[list[str]] = [[] for _ in range(60)]

        def tick() -> None:
            for col in range(60):
                if random.random() < 0.3:
                    c = random.choice("01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン")
                    columns[col].insert(0, c)
                if len(columns[col]) > random.randint(10, 20):
                    columns[col].pop()
            lines = []
            for col in columns:
                s = "".join(f"[rgb(0,{max(50, 255 - i * 15)},0)]{c}[/]" for i, c in enumerate(col))
                lines.append(s)
            self.query_one("#mx-rain").update("\n".join(lines))

        self._rain_timer = self.set_interval(0.1, tick)

    def _start_progress(self) -> None:
        progress = 0
        msgs = cycle([
            "Decrypting dotfiles...", "Loading configurations...",
            "Initialising modules...", "Validating packages...",
            "Preparing installation...", "Almost ready...",
        ])

        def tick() -> None:
            nonlocal progress
            if progress < 100:
                progress += random.randint(1, 3)
                progress = min(progress, 100)
                bar = "█" * (progress // 2) + "░" * (50 - progress // 2)
                self.query_one("#mx-bar").update(f"[green]{bar}[/green]")
                if progress % 15 == 0:
                    self.query_one("#mx-status").update(f"> {next(msgs)}")
                self.query_one("#mx-progress").update(f"Integrity: {progress}%")
                if progress >= 100:
                    self.query_one("#mx-msg").update("✅ Ready!")
                    self.query_one("#mx-status").update("> Ready to proceed")

        self._progress_timer = self.set_interval(0.2, tick)


# ── Custom Widgets ──────────────────────────────────────────────────────────


class BlockSpinner(Static):
    """Block-based spinner that animates while visible."""

    def __init__(self, message: str = "Loading...") -> None:
        super().__init__()
        self._msg = message
        self._frames = [
            "[green]█[/green]░░░", "░[green]█[/green]░░",
            "░░[green]█[/green]░", "░░░[green]█[/green]",
            "░░[green]█[/green]░", "░[green]█[/green]░░",
        ]
        self._idx = 0
        self._timer: Optional[Timer] = None

    def on_mount(self) -> None:
        self._timer = self.set_interval(0.12, self._tick)

    def _tick(self) -> None:
        self._idx = (self._idx + 1) % len(self._frames)
        self.update(f"{self._frames[self._idx]} {self._msg}")

    def stop(self, final: str = "") -> None:
        if self._timer:
            self._timer.stop()
        self.update(f"[green]█[/green] {final or self._msg}")


class ProgressBlocks(Static):
    """Visual progress indicator using filled/empty blocks."""

    def __init__(self, total: int = 20, title: str = "Progress") -> None:
        super().__init__()
        self._total = total
        self._current = 0
        self._title = title

    def set(self, value: int, maximum: Optional[int] = None) -> None:
        if maximum is not None:
            self._total = maximum
        self._current = min(value, self._total)
        pct = int((self._current / self._total) * 100)
        filled = int((self._current / self._total) * self._total)
        blocks = "█" * filled
        spaces = "░" * (self._total - filled)
        color = "red" if pct < 30 else ("yellow" if pct < 70 else "green")
        self.update(f"{self._title}: [{color}]{blocks}[/{color}][white]{spaces}[/white] {pct}%")
