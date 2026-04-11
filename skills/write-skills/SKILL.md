---
name: write-skills
description: How to write effective agent skill content for Claude and Gemini — framing, structure, and model-specific differences. Use add-skill for setup/file location.
argument-hint: [skill-name]
---

For setup (file location, frontmatter, verification), see the `add-skill` skill.
This skill covers how to write skill *content* that works well for both Claude and Gemini.

---

## Writing for both Claude and Gemini

Skills are shared between agents, so write them to work well for both. The two models respond differently to how instructions are framed.

### Framing: declarative over procedural

Gemini responds better to declarative constraints ("the output must include X") than procedural chains ("step 1: do X, step 2: do Y"). Claude handles both, but procedural chains are brittle if Gemini skips or reorders steps.

**Prefer:**
> The APK path must be converted to a Windows path with `wslpath -w` before passing to `adb.exe`.

**Over:**
> Step 1: get the APK path. Step 2: run wslpath -w on it. Step 3: pass it to adb.exe.

Procedural steps are fine for multi-step *workflows* (like build → install → verify) where the order genuinely matters. Use declarative for constraints and facts.

### Framing: positive over negative

Negative instructions ("don't use ./gradlew") are weaker in Gemini than Claude.

**Prefer:**
> Always use `android-gradle` (not `./gradlew` directly) — it sets the correct JBR and SDK paths.

**Over:**
> Don't call ./gradlew directly.

### Placement: critical facts first

Gemini attends less reliably to content in the middle of long context. Put the most important constraints and traps at the top of the skill, before any background or procedural content.

### Verification prompts

Gemini is more likely to hallucinate plausible-sounding file paths or function names. For skills that involve editing code, include an explicit verification instruction:

> Verify every file path and function name exists with Glob or Grep before referencing it in an edit.

Claude will also benefit from this, though it's less prone to the problem.

### When to use examples

Both models benefit from concrete examples. Prefer showing the exact command or code snippet over describing it abstractly. A table of aliases (like in `android-build-install`) is especially useful for Gemini since it removes ambiguity.

---

## Length and scope

- Keep skills focused on one task or domain
- Long skills with many sections get lower average attention from Gemini
- If a skill would exceed ~150 lines, split it into two focused skills
- Background context belongs in GEMINI.md / CLAUDE.md, not in skills

---

## Agent-specific skills

If a skill only makes sense for one agent (e.g., it uses Claude-specific tool syntax), place it in the agent's own stow directory instead of the shared `skills/` folder:

- Claude-only: `stows-optional/claude/.claude/skills/<name>/SKILL.md`
- Gemini-only: `stows-optional/gemini/.gemini/skills/<name>/SKILL.md`
