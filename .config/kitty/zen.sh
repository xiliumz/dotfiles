#!/bin/sh

STATE="${XDG_RUNTIME_DIR:-/tmp}/kitty-zen-mode"

if [ -f "$STATE" ]; then
    kitten @ set-spacing margin=default padding=default
    rm "$STATE"
else
    kitten @ set-spacing \
        margin-h=140 \
        # margin-v=15 \
        padding-h=12 \
        padding-v=8
    touch "$STATE"
fi
