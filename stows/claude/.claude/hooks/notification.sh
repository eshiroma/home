#!/bin/bash
# Notification hook — sends Telegram message when Claude is waiting for input
# Non-blocking: network failures won't block tool execution

[[ -f ~/.localrc ]] && source ~/.localrc
source ~/.claude/hooks/lib/telegram-bridge.sh

# Read JSON from stdin
INPUT=$(cat)

# Extract session ID for topic threading
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [[ -n "$SESSION_ID" ]]; then
    export TG_SESSION_ID="$SESSION_ID"
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [[ -n "$CWD" ]]; then
    pushd "$CWD" > /dev/null 2>&1
fi

IDENTITY=$(tg_identity)

# Send Telegram notification (background, non-blocking)
(tg_send "<b>${IDENTITY} Waiting for input</b>" || true) >/dev/null 2>&1 &

# tmux marker file logic
if [[ -n "$TMUX_PANE" ]]; then
    WINDOW_ID=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null)
    if [[ -n "$WINDOW_ID" ]]; then
        touch "/tmp/claude-blocked-${WINDOW_ID}"
        rm -f "/tmp/claude-thinking-${WINDOW_ID}"
    fi
fi

exit 0
