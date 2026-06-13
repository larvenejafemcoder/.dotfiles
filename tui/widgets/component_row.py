#!/usr/bin/env python3
"""Custom component list item widget for the TUI."""

from typing import Optional, Set

from textual.containers import Container
from textual.widgets import Checkbox, Static


def make_component_row(
    cname: str,
    description: str,
    install_size_kb: Optional[int] = None,
    dependencies: Optional[list] = None,
    selected: bool = False,
    unavailable: bool = False,
    availability_note: str = "",
) -> Container:
    """Build a component row container with checkbox, name, size, and description."""
    size = f"  [{install_size_kb / 1024:.1f} MB]" if install_size_kb else ""
    deps = f"  [{len(dependencies)} dep(s)]" if dependencies else ""
    status = "[x]" if selected else "[ ]"
    warning = " [!]" if unavailable else ""

    cb = Checkbox(
        value=selected,
        id=f"cs-cb-{cname}",
        classes="cs-comp-checkbox",
        disabled=unavailable,
    )
    label = Static(f"{status} {cname}{size}{deps}{warning}", classes="cs-comp-name")
    desc = Static(f"  {description[:70]}", classes="cs-comp-desc")
    return Container(cb, Container(label, desc, classes="cs-comp-info"), classes="cs-comp-row")
