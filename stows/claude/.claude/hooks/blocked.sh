#!/bin/bash
[ -z "$TMUX_PANE" ] && exit 0
raw=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null)
[[ "$raw" =~ (@[0-9]+) ]] || exit 0
win="${BASH_REMATCH[1]}"
touch "/tmp/claude-blocked-${win}"
rm -f "/tmp/claude-thinking-${win}"
