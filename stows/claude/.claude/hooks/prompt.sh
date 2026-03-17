#!/bin/bash
# UserPromptSubmit hook — set tmux thinking marker

# Read stdin (consume required input)
INPUT=$(cat)

# tmux marker file logic
if [[ -n "$TMUX_PANE" ]]; then
    WINDOW_ID=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null)
    if [[ -n "$WINDOW_ID" ]]; then
        touch "/tmp/claude-thinking-${WINDOW_ID}"
        rm -f "/tmp/claude-blocked-${WINDOW_ID}"
    fi
fi

exit 0
