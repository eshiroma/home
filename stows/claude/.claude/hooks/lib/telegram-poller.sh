#!/bin/bash
# Telegram poller daemon
# Runs in background, writes callback/reply results to /tmp files

PID_FILE="/tmp/telegram-poller.pid"
LOG_FILE="/tmp/telegram-poller.log"
LOCK_FILE="/tmp/telegram-poller.lock"
READY_FILE="/tmp/telegram-poller.ready"

# Use flock to ensure only one poller instance runs
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    echo "[$(date)] Another poller already holds the lock, exiting" >> "$LOG_FILE"
    exit 0
fi

# Redirect all output to log
exec >> "$LOG_FILE" 2>&1

# Kill any stale poller before we start
if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[$(date)] Killing stale poller PID $OLD_PID"
        kill "$OLD_PID" 2>/dev/null
        sleep 1
        kill -9 "$OLD_PID" 2>/dev/null
    fi
fi

echo "[$(date)] Telegram poller starting (PID $$)"
echo $$ > "$PID_FILE"
rm -f "$READY_FILE"

# Source env vars
[[ -f ~/.localrc ]] && source ~/.localrc

# Source the bridge library for tg_api
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/telegram-bridge.sh"

# Cleanup on exit
cleanup() {
    rm -f "$PID_FILE" "$READY_FILE"
    echo "[$(date)] Telegram poller exiting (PID $$)"
}
trap cleanup EXIT

# Skip stale updates on startup — retry until we get a clean offset
echo "[$(date)] Fetching initial offset..."
OFFSET=""
for attempt in 1 2 3 4 5 6 7 8 9 10; do
    INIT_RESPONSE=$(tg_api "getUpdates" "{\"offset\":-1,\"timeout\":0}")
    INIT_OK=$(echo "$INIT_RESPONSE" | jq -r '.ok' 2>/dev/null)
    if [[ "$INIT_OK" == "true" ]]; then
        OFFSET=$(echo "$INIT_RESPONSE" | jq -r '[.result[]?.update_id] | if length > 0 then max + 1 else -1 end' 2>/dev/null)
        break
    fi
    echo "[$(date)] Initial offset fetch failed (attempt $attempt), retrying..."
    sleep 2
done
if [[ -z "$OFFSET" || "$OFFSET" == "null" ]]; then
    OFFSET=-1
fi
echo "[$(date)] Starting offset: $OFFSET"

# Signal readiness
touch "$READY_FILE"
echo "[$(date)] Poller ready"

# Main polling loop
while true; do
    RESPONSE=$(tg_api "getUpdates" "{\"offset\":${OFFSET},\"timeout\":5}")

    if [[ -z "$RESPONSE" ]]; then
        echo "[$(date)] Empty response from getUpdates, retrying..."
        sleep 2
        continue
    fi

    OK=$(echo "$RESPONSE" | jq -r '.ok' 2>/dev/null)
    if [[ "$OK" != "true" ]]; then
        ERR_CODE=$(echo "$RESPONSE" | jq -r '.error_code // 0' 2>/dev/null)
        if [[ "$ERR_CODE" == "409" ]]; then
            # Conflict with another instance — retry quickly
            sleep 1
        else
            echo "[$(date)] getUpdates error: $RESPONSE"
            sleep 5
        fi
        continue
    fi

    # Process each update
    UPDATE_COUNT=$(echo "$RESPONSE" | jq '.result | length' 2>/dev/null)
    if [[ "$UPDATE_COUNT" -gt 0 ]]; then
        echo "[$(date)] Processing $UPDATE_COUNT update(s)"
    fi

    # Process callback queries
    echo "$RESPONSE" | jq -c '.result[] | select(.callback_query != null) | .callback_query' 2>/dev/null | while read -r cb; do
        CB_ID=$(echo "$cb" | jq -r '.id')
        CB_DATA=$(echo "$cb" | jq -r '.data // ""')

        echo "[$(date)] Callback: id=$CB_ID data=$CB_DATA"

        # Parse callback_data as "{msg_id}:{value}"
        if [[ "$CB_DATA" =~ ^([0-9]+):(.+)$ ]]; then
            MSG_ID="${BASH_REMATCH[1]}"
            VALUE="${BASH_REMATCH[2]}"
            CB_FILE="/tmp/telegram-cb-${MSG_ID}"

            # Write value and callback_id to file
            printf '%s\n%s\n' "$VALUE" "$CB_ID" > "$CB_FILE"
            echo "[$(date)] Wrote callback to $CB_FILE: value=$VALUE"

            # Acknowledge callback
            ACK_BODY=$(jq -n --arg id "$CB_ID" '{callback_query_id: $id}')
            tg_api "answerCallbackQuery" "$ACK_BODY" > /dev/null
        else
            echo "[$(date)] Unrecognized callback_data format: $CB_DATA"
        fi
    done

    # Process message replies
    echo "$RESPONSE" | jq -c '.result[] | select(.message != null and .message.reply_to_message != null) | .message' 2>/dev/null | while read -r msg; do
        ORIG_MSG_ID=$(echo "$msg" | jq -r '.reply_to_message.message_id')
        MSG_TEXT=$(echo "$msg" | jq -r '.text // ""')

        echo "[$(date)] Reply to msg $ORIG_MSG_ID: $MSG_TEXT"

        REPLY_FILE="/tmp/telegram-reply-${ORIG_MSG_ID}"
        echo "$MSG_TEXT" > "$REPLY_FILE"
    done

    # Advance offset
    MAX_UPDATE_ID=$(echo "$RESPONSE" | jq -r '[.result[]?.update_id] | if length > 0 then max else empty end' 2>/dev/null)
    if [[ -n "$MAX_UPDATE_ID" && "$MAX_UPDATE_ID" != "null" ]]; then
        OFFSET=$(( MAX_UPDATE_ID + 1 ))
    fi

    # Cleanup stale files older than 1 hour
    find /tmp -name "telegram-cb-*" -mmin +60 -delete 2>/dev/null
    find /tmp -name "telegram-reply-*" -mmin +60 -delete 2>/dev/null
done
