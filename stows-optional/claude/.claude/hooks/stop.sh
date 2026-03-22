#!/bin/bash
# Stop hook — cleanup tmux markers and send Telegram done notification
# Non-blocking: network failures won't block tool execution

[[ -f ~/.localrc ]] && source ~/.localrc
source ~/.claude/hooks/lib/telegram-bridge.sh

# Read stdin (not used but required to consume it)
INPUT=$(cat)

# Extract session ID for topic threading
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [[ -n "$SESSION_ID" ]]; then
    export TG_SESSION_ID="$SESSION_ID"
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [[ -n "$CWD" ]]; then
    pushd "$CWD" > /dev/null 2>&1
fi

# tmux cleanup
if [[ -n "$TMUX_PANE" ]]; then
    WINDOW_ID=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null)
    if [[ -n "$WINDOW_ID" ]]; then
        rm -f "/tmp/claude-thinking-${WINDOW_ID}"
        rm -f "/tmp/claude-blocked-${WINDOW_ID}"
    fi
fi

IDENTITY=$(tg_identity)

# Send Telegram notification (background, non-blocking)
(tg_send "<b>${IDENTITY} Done</b>" || true) >/dev/null 2>&1 &

exit 0
