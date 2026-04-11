---
name: add-skill
description: Add a new agent skill to the home repo so it's available to all agents (Claude, Gemini, etc.)
argument-hint: [skill-name]
---

Skills are agent-agnostic and live in the home repo at `~/local/github.com/eshiroma/home/skills/`.
They are fanned out to each agent's skills directory via symlinks managed by `make link-agnostic-skills`.

## Step 1: Create the skill file

```
~/local/github.com/eshiroma/home/skills/<skill-name>/SKILL.md
```

Use this frontmatter:

```markdown
---
name: <skill-name>
description: <one-line description — shown to agents to decide when to invoke>
argument-hint: [optional args]
---
```

## Step 2: Verify it's live

Agent skill directories (`~/.claude/skills/`, `~/.gemini/skills/`, `~/.agents/skills/`) are directory-level symlinks into the `skills/` folder, so the new skill is automatically available — no `make` step needed.

```bash
ls ~/.claude/skills/<skill-name>/
```

## Notes

- Agent-specific skills (not shared) go in `stows-optional/claude/.claude/skills/` or `stows-optional/gemini/.gemini/skills/` directly as a subdirectory (not a symlink)
- Do NOT place skills in `~/.claude/skills/` directly; they won't be version-controlled
- Commit only: `skills/<name>/SKILL.md`
