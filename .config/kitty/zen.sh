#!/bin/sh
# Zen mode: puts two empty black "spacer" windows on the left and right of the
# focused window. The main window keeps its own background color and opacity.

SPACER_PCT=14   # width of each side spacer, in % of the tab width
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# Read the focused tab: its id, active window, layout, and any existing spacers.
eval "$(kitten @ ls | python3 -c '
import json, sys
data = json.load(sys.stdin)
osw = next((o for o in data if o.get("is_focused")), None) or next(o for o in data if o.get("is_active"))
tab = next(t for t in osw["tabs"] if t.get("is_active"))
win = next(w for w in tab["windows"] if w.get("is_active"))
spacers = [str(w["id"]) for w in tab["windows"] if w.get("user_vars", {}).get("zen_spacer")]
print("TAB=%s WIN=%s PID=%s LAYOUT=%s SPACERS=\"%s\"" % (tab["id"], win["id"], win["pid"], tab["layout"], " ".join(spacers)))
')"

STATE="$STATE_DIR/kitty-zen-tab-$TAB"

if [ -n "$SPACERS" ]; then
    # --- Zen off ---
    for id in $SPACERS; do
        kitten @ close-window --ignore-no-match --match "id:$id"
    done
    if [ -f "$STATE" ]; then
        . "$STATE"   # sets PREV_LAYOUT and MAIN
        kitten @ set-spacing --match "id:$MAIN" padding=default
        kitten @ goto-layout --match "id:$TAB" "$PREV_LAYOUT"
        rm -f "$STATE"
    fi
else
    # --- Zen on ---
    printf 'PREV_LAYOUT=%s\nMAIN=%s\n' "$LAYOUT" "$WIN" > "$STATE"

    kitten @ goto-layout --match "id:$TAB" splits

    # Empty, black, cursorless window that ignores typing.
    # zen_watcher.py closes it instantly when the main window closes; the
    # tail --pid is a ~1s fallback in case the watcher isn't loaded.
    spacer() {
        kitten @ launch --match "id:$TAB" --next-to "id:$WIN" \
            --location="$1" --bias="$2" \
            --keep-focus --var zen_spacer=1 --title " " \
            --color background=#000000 \
            sh -c 'stty -echo -icanon 2>/dev/null; printf "\033[?25l"; exec tail --pid="$1" -f /dev/null' sh "$PID" \
            >/dev/null
    }

    # Right spacer takes SPACER_PCT% of the full width.
    spacer vsplit "$SPACER_PCT"
    # Left spacer splits what's left, so scale its bias to get the same width.
    spacer before $(( SPACER_PCT * 100 / (100 - SPACER_PCT) ))

    kitten @ set-spacing --match "id:$WIN" padding-h=12 padding-v=8
fi
