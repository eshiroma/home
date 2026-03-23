---
name: search-sessions
description: Find previous agent sessions by searching prompt history
argument-hint: [search-term]
disable-model-invocation: true
allowed-tools: Bash(cat *), Bash(grep *), Bash(jq *)
---

Search for previous sessions matching the given search term.

Run the following command and present the results:

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

Present the results as a readable table or list showing:
- Project name
- Date/time started
- First prompt (truncated if long)
- Number of matching messages
- Session ID (for reference)
