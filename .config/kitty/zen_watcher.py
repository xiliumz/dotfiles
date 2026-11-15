"""Zen mode helper for zen.sh.

When the last real window in a tab closes (e.g. ctrl+d), close the black
side spacer windows right away so the tab/OS window closes with it.
"""
from typing import Any

from kitty.boss import Boss
from kitty.window import Window


def is_spacer(w: Window) -> bool:
    return bool(w.user_vars.get('zen_spacer'))


def on_close(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if is_spacer(window):
        return
    tab = boss.tab_for_id(window.tab_id)
    if tab is None:
        return
    others = [w for w in tab if w.id != window.id]
    if others and all(is_spacer(w) for w in others):
        for w in others:
            boss.mark_window_for_close(w)
