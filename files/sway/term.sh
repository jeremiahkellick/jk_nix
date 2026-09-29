#!/bin/sh
pids=$(swaymsg -t get_tree | jq -r '
def mru:
  ((.nodes // []) + (.floating_nodes // [])) as $kids
  | if ($kids | length) == 0 then .
    else . as $n | $n.focus[] as $id | ($kids[] | select(.id == $id)) | mru
    end;
mru | select(.app_id == "foot") | .pid // empty')

for pid in $pids; do
    child=$(pgrep -P "$pid" | head -n1)
    if [ -n "$child" ]; then
        cwd=$(readlink -f "/proc/$child/cwd" 2>/dev/null)
        if [ -n "$cwd" ]; then
            break
        fi
    fi
done

if [ -n "$cwd" ]; then
    exec foot --working-directory "$cwd"
else
    exec foot
fi
