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

## Step 2: Link the skill into agent directories

```bash
cd ~/local/github.com/eshiroma/home && make link-agnostic-skills
```

This creates symlinks in:
- `stows-optional/claude/.claude/skills/<skill-name>` → `../../../../skills/<skill-name>`
- `stows-optional/gemini/.gemini/skills/<skill-name>` → `../../../../skills/<skill-name>`

## Step 3: Restow so symlinks appear in home directory

```bash
cd ~/local/github.com/eshiroma/home && make stow-claude stow-gemini
```

Verify:
```bash
ls -la ~/.claude/skills/
ls -la ~/.gemini/skills/
```

Both should show the new skill symlinked.

## Notes

- Agent-specific skills (not shared) go in `stows-optional/claude/.claude/skills/` or `stows-optional/gemini/.gemini/skills/` directly — skip `link-agnostic-skills`
- Do NOT place skills in `~/.claude/skills/` directly; they won't be version-controlled
- Commit all three artifacts: `skills/<name>/SKILL.md`, and the two symlinks in `stows-optional/`
