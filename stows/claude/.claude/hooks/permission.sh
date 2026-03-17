#!/bin/bash
# PermissionRequest hook — sends Telegram message and waits for user response
# Falls back to deny on network failure (|| true guards prevent blocking)

[[ -f ~/.localrc ]] && source ~/.localrc
source ~/.claude/hooks/lib/telegram-bridge.sh

# Read JSON from stdin
INPUT=$(cat)

# Extract session ID for topic threading
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [[ -n "$SESSION_ID" ]]; then
    export TG_SESSION_ID="$SESSION_ID"
fi

# Extract fields
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [[ -n "$CWD" ]]; then
    pushd "$CWD" > /dev/null 2>&1
fi

IDENTITY=$(tg_identity)

# Format message based on tool type
case "$TOOL_NAME" in
    Bash)
        CMD=$(echo "$TOOL_INPUT" | jq -r '.command // ""')
        DESC=$(echo "$TOOL_INPUT" | jq -r '.description // ""')
        DETAILS="<b>Command:</b>\n<pre>$(echo "$CMD" | head -c 1000 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</pre>"
        if [[ -n "$DESC" ]]; then
            DETAILS+="\n<b>Description:</b> $(echo "$DESC" | head -c 200 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
        fi
        ;;
    Edit)
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        OLD_STR=$(echo "$TOOL_INPUT" | jq -r '.old_string // ""' | head -c 200)
        NEW_STR=$(echo "$TOOL_INPUT" | jq -r '.new_string // ""' | head -c 200)
        DETAILS="<b>File:</b> <code>$(echo "$FILE_PATH" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</code>"
        DETAILS+="\n<b>Old:</b>\n<pre>$(echo "$OLD_STR" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</pre>"
        DETAILS+="\n<b>New:</b>\n<pre>$(echo "$NEW_STR" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</pre>"
        ;;
    Write)
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        CONTENT=$(echo "$TOOL_INPUT" | jq -r '.content // ""')
        CONTENT_LEN=${#CONTENT}
        DETAILS="<b>File:</b> <code>$(echo "$FILE_PATH" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</code>"
        DETAILS+="\n<b>Content length:</b> ${CONTENT_LEN} chars"
        ;;
    *)
        KEYS=$(echo "$TOOL_INPUT" | jq -r 'keys | join(", ")' 2>/dev/null)
        DETAILS="<b>Tool:</b> <code>$TOOL_NAME</code>"
        DETAILS+="\n<b>Input keys:</b> $KEYS"
        ;;
esac

# Build full message (cap at 3500 chars)
HEADER="<b>${IDENTITY} Permission Request</b>"
FULL_MSG=$(printf "%s\n\n<b>Tool:</b> %s\n%b" "$HEADER" "$TOOL_NAME" "$DETAILS")
if [[ ${#FULL_MSG} -gt 3500 ]]; then
    FULL_MSG="${FULL_MSG:0:3500}..."
fi

# Start poller (non-blocking guard — if poller fails, fall through to inline polling)
tg_ensure_poller >&2 || true

# Send with keyboard (if send fails, deny gracefully)
MSG_ID=$(tg_send_keyboard "$FULL_MSG" "Allow:allow" "Deny:deny" "Explain:explain" "Later:later") || true
if [[ -z "$MSG_ID" ]]; then
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"Failed to send Telegram message"}}}'
    exit 0
fi

echo "Sent permission request as message $MSG_ID" >&2

wait_and_respond() {
    local wait_msg_id="$1"
    local response
    response=$(tg_wait_callback "$wait_msg_id" 900)
    echo "$response"
}

RESPONSE=$(wait_and_respond "$MSG_ID")

# Handle "explain" flow
if [[ "$RESPONSE" == "explain" ]]; then
    # Append full tool_input as <pre> block
    FULL_INPUT=$(echo "$TOOL_INPUT" | jq '.' 2>/dev/null || echo "$TOOL_INPUT")
    FULL_INPUT_HTML="<pre>$(echo "$FULL_INPUT" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</pre>"

    # Edit original message to append full details
    CURRENT_TEXT="${FULL_MSG}\n\n<b>Full input:</b>"
    tg_edit "$MSG_ID" "$(printf '%b' "$CURRENT_TEXT")" >&2 || true

    # Split and send full input if needed (4096 char limit)
    CHUNK_SIZE=3500
    INPUT_LEN=${#FULL_INPUT_HTML}
    if [[ $INPUT_LEN -le $CHUNK_SIZE ]]; then
        tg_send "$FULL_INPUT_HTML" >&2 || true
    else
        OFFSET=0
        while [[ $OFFSET -lt $INPUT_LEN ]]; do
            CHUNK="${FULL_INPUT_HTML:$OFFSET:$CHUNK_SIZE}"
            tg_send "$CHUNK" >&2 || true
            OFFSET=$(( OFFSET + CHUNK_SIZE ))
        done
    fi

    # Send new keyboard
    NEW_MSG_ID=$(tg_send_keyboard "<b>${IDENTITY} Permission Request (cont.)</b>\nAllow, deny, or respond later?" \
        "Allow:allow" "Deny:deny" "Later:later") || true

    if [[ -n "$NEW_MSG_ID" ]]; then
        RESPONSE=$(wait_and_respond "$NEW_MSG_ID")
    else
        RESPONSE="deny"
    fi
fi

# Output decision
case "$RESPONSE" in
    allow)
        echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
        ;;
    later)
        echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"User will respond later - try an alternative approach or move to a different task"}}}'
        ;;
    *)
        # deny or anything else
        echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"Permission denied by user"}}}'
        ;;
esac

exit 0
