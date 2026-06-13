#!/usr/bin/env python3
"""Reusable modal screens for the TUI."""

import asyncio

from textual import on
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Input, Static


class ConfirmModal(ModalScreen):
    def __init__(self, title: str, message: str, confirm_text: str = "Yes",
                 cancel_text: str = "Cancel", danger: bool = False) -> None:
        super().__init__()
        self._title = title
        self._message = message
        self._confirm_text = confirm_text
        self._cancel_text = cancel_text
        self._danger = danger

    def compose(self) -> Vertical:
        with Vertical(id="modal"):
            yield Static(self._title, id="modal-title")
            yield Static(self._message, id="modal-text")
            with Horizontal(id="modal-buttons"):
                variant = "error" if self._danger else "primary"
                yield Button(self._confirm_text, id="confirm", variant=variant)
                yield Button(self._cancel_text, id="cancel", variant="default")

    @on(Button.Pressed, "#confirm")
    def confirm(self) -> None:
        self.dismiss(True)

    @on(Button.Pressed, "#cancel")
    def cancel(self) -> None:
        self.dismiss(False)


class MessageModal(ModalScreen):
    def __init__(self, title: str, message: str, auto_dismiss_sec: float = 0) -> None:
        super().__init__()
        self._title = title
        self._message = message
        self._auto_dismiss = auto_dismiss_sec

    def compose(self) -> Vertical:
        with Vertical(id="modal"):
            yield Static(self._title, id="modal-title")
            yield Static(self._message, id="modal-text")
            with Horizontal(id="modal-buttons"):
                yield Button("OK", id="ok", variant="primary")

    async def on_mount(self) -> None:
        if self._auto_dismiss > 0:
            await asyncio.sleep(self._auto_dismiss)
            self.dismiss(True)

    @on(Button.Pressed, "#ok")
    def ok(self) -> None:
        self.dismiss(True)


class InputModal(ModalScreen):
    def __init__(self, title: str, prompt: str, default: str = "") -> None:
        super().__init__()
        self._title = title
        self._prompt = prompt
        self._default = default

    def compose(self) -> Vertical:
        with Vertical(id="modal"):
            yield Static(self._title, id="modal-title")
            yield Static(self._prompt, id="modal-text")
            yield Input(placeholder=self._default, id="modal-input")
            with Horizontal(id="modal-buttons"):
                yield Button("OK", id="ok", variant="primary")
                yield Button("Cancel", id="cancel", variant="default")

    @on(Input.Submitted)
    @on(Button.Pressed, "#ok")
    def confirm(self) -> None:
        input_widget = self.query_one("#modal-input", Input)
        result = input_widget.value or self._default
        self.dismiss(result)

    @on(Button.Pressed, "#cancel")
    def cancel(self) -> None:
        self.dismiss(None)
