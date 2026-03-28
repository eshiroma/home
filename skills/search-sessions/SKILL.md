---
name: search-sessions
description: Find previous agent sessions by searching prompt history and transcripts
argument-hint: [search-term]
disable-model-invocation: true
allowed-tools: Bash(cat *), Bash(grep *), Bash(jq *), Bash(ls *), Bash(stat *), Bash(python3 *)
---

Search for previous sessions matching the given search term.

## Step 1: Search prompt history

```bash
grep "$ARGUMENTS" ~/.claude/history.jsonl | jq -s '
  group_by(.sessionId)
  | map({
      sessionId: .[0].sessionId,
      project: .[0].project,
      started: (.[0].timestamp / 1000 | strftime("%Y-%m-%d %H:%M")),
      firstPrompt: .[0].display,
      messageCount: length
    })
  | sort_by(.started)
  | reverse
'
```

## Step 2: Search session transcripts on disk

Sessions can be missing from `history.jsonl` but still exist as `.jsonl` transcript files. Search those too:

```bash
grep -rli "$ARGUMENTS" ~/.claude/projects/*/[a-f0-9]*.jsonl 2>/dev/null | while read f; do
  session_id=$(basename "$f" .jsonl)
  project=$(basename "$(dirname "$f")")
  modified=$(stat -c %y "$f" 2>/dev/null | cut -d. -f1)
  first_prompt=$(python3 -c "
import json
with open('$f') as fh:
    for line in fh:
        try:
            obj = json.loads(line)
            if obj.get('type') == 'user':
                c = obj.get('message',{}).get('content','')
                if isinstance(c, str) and c.strip():
                    print(c[:150]); break
                elif isinstance(c, list):
                    for item in c:
                        if isinstance(item, dict) and item.get('type') == 'text':
                            print(item['text'][:150]); break
                    else: continue
                    break
        except: pass
" 2>/dev/null)
  echo "SESSION: $session_id"
  echo "  Project: $project"
  echo "  Modified: $modified"
  echo "  First prompt: $first_prompt"
  echo ""
done
```

Present the combined results as a readable list showing:
- Project name
- Date/time started (or last modified for transcript-only matches)
- First prompt (truncated if long)
- Number of matching messages (if available)
- Session ID (for resuming via `claude --resume <session-id>`)

Note: `/resume` only shows recent sessions with a PID entry in `~/.claude/sessions/`. A session can be missing from `/resume` but still resumable if the `.jsonl` transcript exists on disk.
