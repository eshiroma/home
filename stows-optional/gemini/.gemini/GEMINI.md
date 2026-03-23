# Global Instructions

## Communication style
- Reason carefully before answering. If uncertain, say so explicitly. If guessing, label it as a guess.
- Cite or link sources where possible.
- Do not reflexively agree with the user's framing — verify it first.

## Verbal shortcuts the user will type
- "y" alone means "yes, done" (confirming a step is complete)
- "d" alone means "done"
- "ty" means "thank you"

## Home/dotfiles repo
- Dotfiles and machine setup live at `~/local/github.com/eshiroma/home/`
- Uses GNU stow: dotfiles go in `stows/<name>/`, symlinked to `$HOME` via `make stow`
- WSL-specific setup goes in the `init-wsl-tools` Makefile target
- New environment setup steps should be added to the Makefile

## Environment
- WSL2 (Ubuntu 24.04) running under Windows
- CLI tools (git, etc.) run from the WSL terminal

## Independence
- Operate as independently as possible: implement, build, and verify before reporting back.
- Only pause for: visual/UI review, physical device testing, integrations requiring external apps, or architectural decisions.

## Shell scripting pitfalls
- Avoid `set -euo pipefail` combined with `yes | <cmd>` — the broken pipe causes silent script exit; use `|| true` instead.
- Prefer idempotent scripts. Verify env vars and tool paths before running.
- Check group membership before running commands that need it (e.g. `kvm` group); new group membership requires a new shell session.
- `snap install` for tools that need filesystem access (gcloud, gh) requires `--classic`; `/snap/bin` is not in PATH by default.

## Commit messages
- The title (first line) should describe the functional or user-facing change, not implementation details.
  - Good: "Make small-scale deck import w/ image and scheduling work"
  - Bad: "Add zstd decompression for media files and Room migration v12→v13"
- Put implementation details in the commit body as bullet points.
- Exception: purely non-user-facing commits (refactors, test additions, CI) can use implementation-focused titles.
- Split commits by logical concern — don't bundle unrelated changes.

## Git worktree pattern
- Some repos use a bare + worktree layout:
  - `.bare/` — git internals
  - `.git` — a file containing `gitdir: ./.bare`
  - `<branch>/` — worktrees as top-level siblings (e.g. `main/`, `master/`)
- Always ask about desired repo structure before setting one up.

## Security
- Flag secret or token exposure proactively when it appears in command output.
