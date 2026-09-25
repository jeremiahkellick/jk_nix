#!/bin/sh
# Open a new foot terminal in the focused window's cwd
pid=$(swaymsg -t get_tree | jq -r 'first(.. | objects | select(.focused==true) | .pid) // empty')
if [ -n "$pid" ]; then
    child=$(pgrep -P "$pid" | head -n1)
    if [ -n "$child" ]; then
        cwd=$(readlink -f "/proc/$child/cwd" 2>/dev/null)
    fi
fi
if [ -n "$cwd" ]; then
    exec foot --working-directory "$cwd"
else
    exec foot
fi
