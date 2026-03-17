#!/bin/bash
# Telegram bridge shared library
# Source this file to use tg_* functions

# tg_api METHOD JSON_BODY — POST to Telegram Bot API, return response JSON
tg_api() {
    local method="$1"
    local body="$2"
    curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/${method}" \
        -H "Content-Type: application/json" \
        -d "$body"
}

# tg_identity — returns [MACHINE_TAG/project]
tg_identity() {
    echo "[${MACHINE_TAG}/${PWD##*/}]"
}

# tg_get_session_thread — return thread ID for current Claude session
# Creates a forum topic if needed, caches in /tmp
tg_get_session_thread() {
    local session_id="${TG_SESSION_ID:-$$}"
    local cache_file="/tmp/telegram-session-thread-${session_id}"

    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return 0
    fi

    local topic_name="${MACHINE_TAG}/${PWD##*/}"
    local thread_id
    thread_id=$(tg_create_topic "$topic_name")

    if [[ -n "$thread_id" && "$thread_id" != "null" ]]; then
        echo "$thread_id" > "$cache_file"
        echo "$thread_id"
    else
        # Fall back to no thread (main chat)
        echo "" >&2
        echo ""
    fi
}

# tg_create_topic NAME — create forum topic, return message_thread_id
tg_create_topic() {
    local name="$1"
    local body
    body=$(jq -n --arg chat_id "$TELEGRAM_CHAT_ID" --arg name "$name" \
        '{chat_id: ($chat_id | tonumber), name: $name}')
    local response
    response=$(tg_api "createForumTopic" "$body")
    echo "$response" | jq -r '.result.message_thread_id // empty' 2>/dev/null
}

# tg_send TEXT — send HTML message, prints message_id to stdout
tg_send() {
    local text="$1"
    local thread_id
    thread_id=$(tg_get_session_thread)

    local body
    if [[ -n "$thread_id" ]]; then
        body=$(jq -n \
            --arg chat_id "$TELEGRAM_CHAT_ID" \
            --arg text "$text" \
            --argjson thread_id "$thread_id" \
            '{chat_id: ($chat_id | tonumber), text: $text, parse_mode: "HTML", message_thread_id: $thread_id}')
    else
        body=$(jq -n \
            --arg chat_id "$TELEGRAM_CHAT_ID" \
            --arg text "$text" \
            '{chat_id: ($chat_id | tonumber), text: $text, parse_mode: "HTML"}')
    fi

    local response
    response=$(tg_api "sendMessage" "$body")
    local ok
    ok=$(echo "$response" | jq -r '.ok' 2>/dev/null)
    if [[ "$ok" != "true" ]]; then
        echo "tg_send error: $response" >&2
        return 1
    fi
    echo "$response" | jq -r '.result.message_id'
}

# tg_send_keyboard TEXT BTN... — send message with inline keyboard
# Buttons as "Label:value" pairs
# Prints message_id to stdout
tg_send_keyboard() {
    local text="$1"
    shift
    local buttons=("$@")

    # First send the message to get message_id
    local msg_id
    msg_id=$(tg_send "$text")
    if [[ -z "$msg_id" ]]; then
        echo "tg_send_keyboard: failed to send initial message" >&2
        return 1
    fi

    # Build keyboard JSON with callback_data = "{msg_id}:{value}"
    local keyboard_buttons="[]"
    for btn in "${buttons[@]}"; do
        local label="${btn%%:*}"
        local value="${btn#*:}"
        local cb_data="${msg_id}:${value}"
        keyboard_buttons=$(echo "$keyboard_buttons" | jq \
            --arg lbl "$label" \
            --arg cb "$cb_data" \
            '. + [{"text": $lbl, "callback_data": $cb}]')
    done

    local keyboard
    keyboard=$(jq -n --argjson btns "$keyboard_buttons" \
        '{"inline_keyboard": [$btns]}')

    # Edit message to add the keyboard
    local edit_body
    edit_body=$(jq -n \
        --arg chat_id "$TELEGRAM_CHAT_ID" \
        --argjson msg_id "$msg_id" \
        --argjson keyboard "$keyboard" \
        '{chat_id: ($chat_id | tonumber), message_id: $msg_id, reply_markup: $keyboard}')

    local edit_response
    edit_response=$(tg_api "editMessageReplyMarkup" "$edit_body")
    local ok
    ok=$(echo "$edit_response" | jq -r '.ok' 2>/dev/null)
    if [[ "$ok" != "true" ]]; then
        echo "tg_send_keyboard edit error: $edit_response" >&2
    fi

    echo "$msg_id"
}

# tg_edit MESSAGE_ID TEXT — edit existing message (HTML parse_mode)
tg_edit() {
    local msg_id="$1"
    local text="$2"

    local body
    body=$(jq -n \
        --arg chat_id "$TELEGRAM_CHAT_ID" \
        --argjson msg_id "$msg_id" \
        --arg text "$text" \
        '{chat_id: ($chat_id | tonumber), message_id: $msg_id, text: $text, parse_mode: "HTML"}')

    local response
    response=$(tg_api "editMessageText" "$body")
    local ok
    ok=$(echo "$response" | jq -r '.ok' 2>/dev/null)
    if [[ "$ok" != "true" ]]; then
        echo "tg_edit error: $response" >&2
        return 1
    fi
}

# tg_answer_cb CALLBACK_ID — acknowledge callback query
tg_answer_cb() {
    local cb_id="$1"
    local body
    body=$(jq -n --arg id "$cb_id" '{callback_query_id: $id}')
    tg_api "answerCallbackQuery" "$body" > /dev/null
}

# _tg_poller_running — check if poller daemon is alive
_tg_poller_running() {
    local pid_file="/tmp/telegram-poller.pid"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && return 0
    fi
    return 1
}

# tg_wait_callback MSG_ID TIMEOUT_SEC — block until callback arrives or timeout
# Returns callback value
# When poller is running, only watches /tmp files (no competing getUpdates calls).
# Falls back to direct inline polling only when poller is NOT running.
tg_wait_callback() {
    local msg_id="$1"
    local timeout="${2:-60}"
    local cb_file="/tmp/telegram-cb-${msg_id}"
    local elapsed=0
    local poll_interval=3
    local use_poller=false

    if _tg_poller_running; then
        use_poller=true
    fi

    while [[ $elapsed -lt $timeout ]]; do
        # Check if poller already delivered the callback
        if [[ -f "$cb_file" ]]; then
            local value
            value=$(head -1 "$cb_file")
            rm -f "$cb_file"
            echo "$value"
            return 0
        fi

        # Only do direct polling if poller is NOT running (avoids competing getUpdates)
        if [[ "$use_poller" == "false" ]] && (( elapsed % poll_interval == 0 )); then
            local response
            response=$(tg_api "getUpdates" '{"timeout":2,"allowed_updates":["callback_query"]}')
            local ok
            ok=$(echo "$response" | jq -r '.ok' 2>/dev/null)
            if [[ "$ok" == "true" ]]; then
                # Look for a callback matching our msg_id
                local match
                match=$(echo "$response" | jq -r --arg mid "$msg_id" '
                    [.result[] | select(.callback_query.data != null) |
                     .callback_query | select(.data | startswith($mid + ":"))] |
                    first // empty' 2>/dev/null)
                if [[ -n "$match" ]]; then
                    local value cb_id max_uid
                    value=$(echo "$match" | jq -r '.data' | sed "s/^${msg_id}://")
                    cb_id=$(echo "$match" | jq -r '.id')
                    # Acknowledge callback
                    tg_answer_cb "$cb_id" 2>/dev/null
                    # Advance offset to confirm this update
                    max_uid=$(echo "$response" | jq -r '[.result[]?.update_id] | if length > 0 then max + 1 else empty end' 2>/dev/null)
                    if [[ -n "$max_uid" ]]; then
                        tg_api "getUpdates" "{\"offset\":${max_uid},\"timeout\":0}" > /dev/null 2>&1
                    fi
                    echo "$value"
                    return 0
                fi
                # Advance offset even if no matching callback (to not re-process)
                local max_uid
                max_uid=$(echo "$response" | jq -r '[.result[]?.update_id] | if length > 0 then max + 1 else empty end' 2>/dev/null)
                if [[ -n "$max_uid" ]]; then
                    tg_api "getUpdates" "{\"offset\":${max_uid},\"timeout\":0}" > /dev/null 2>&1
                fi
            fi
        fi

        sleep 1
        elapsed=$(( elapsed + 1 ))
    done

    return 1
}

# tg_wait_reply MSG_ID TIMEOUT_SEC — block until reply arrives or timeout
# Returns reply text
tg_wait_reply() {
    local msg_id="$1"
    local timeout="${2:-60}"
    local reply_file="/tmp/telegram-reply-${msg_id}"
    local elapsed=0

    while [[ $elapsed -lt $timeout ]]; do
        if [[ -f "$reply_file" ]]; then
            local text
            text=$(cat "$reply_file")
            rm -f "$reply_file"
            echo "$text"
            return 0
        fi
        sleep 1
        elapsed=$(( elapsed + 1 ))
    done

    return 1
}

# tg_ensure_poller — start poller daemon if not running
# Waits for poller to signal readiness before returning
tg_ensure_poller() {
    local pid_file="/tmp/telegram-poller.pid"
    local ready_file="/tmp/telegram-poller.ready"
    local poller_script="$(dirname "${BASH_SOURCE[0]}")/telegram-poller.sh"

    # Check if poller is already running
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
        rm -f "$pid_file" "$ready_file"
    fi

    if [[ ! -f "$poller_script" ]]; then
        echo "tg_ensure_poller: poller script not found at $poller_script" >&2
        return 1
    fi

    rm -f "$ready_file"
    setsid bash "$poller_script" &
    disown

    # Wait for poller to signal readiness (up to 10 seconds)
    local waited=0
    while [[ $waited -lt 10 ]]; do
        if [[ -f "$ready_file" ]]; then
            return 0
        fi
        sleep 1
        waited=$(( waited + 1 ))
    done

    # Check if it started even without ready signal
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi

    echo "tg_ensure_poller: poller failed to start within 10 seconds" >&2
    return 1
}
