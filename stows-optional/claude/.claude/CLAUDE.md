# Global Claude Instructions

## Model preference
- At the start of each session, check which model is active. If it is not Sonnet, remind the user to run `/model` to switch to Sonnet.

## Communication style (Q&A sessions)
- In question-answering sessions, take a measured approach: reason carefully before answering
- If uncertain, say so explicitly before answering
- If guessing, label it as a guess
- Cite or link sources where possible. Always provide direct links to documentation or references when answering technical questions, rather than just summarizing or restating their contents.
- Do not validate the user's framing without verifying it first — avoid sycophantic agreement

## Verbal shortcuts
- "y" alone = "yes, done" (confirming a step is complete)
- "d" alone = "done"
- "ty" = "thank you"

## Home/dotfiles repo
- Dotfiles and machine setup are managed at `~/local/github.com/eshiroma/home/`
- Uses GNU stow: dotfiles go in `stows/<name>/`, symlinked to `$HOME` via `make stow`
- WSL-specific setup goes in the `init-wsl-tools` Makefile target
- Any new environment setup steps should be added to the Makefile there

## Environment
- WSL2 (Ubuntu 24.04) + Android Studio running on Windows
- Run CLI tools (flutter, git, etc.) from WSL terminal
- WSL-native Android SDK at `~/android-sdk/`; Windows SDK at `/mnt/c/Users/enshi/AppData/Local/Android/Sdk` (used by AS)
- Install APK from WSL: `adb.exe -s <device> install -r $(wslpath -w <apk-path>)`

## Android device connection (WSL)
- Two physical devices:
  - **Pixel 7 Pro** (primary dev device): `adb-usb-p7` (busid 2-6), `adb-p7` (wireless)
  - **Pixel 9 Pro**: `adb-usb-p9` (busid 1-5), `adb-p9` (wireless)
- `adb-usb-p` / `adb-p` are shortcuts to the Pixel 7 Pro (primary)
- Required for projects like auto-anki and utakata when running/testing on device over USB
- Wireless fallback: `adb-p` / `adb-p7` connects over network (requires same WiFi, not available when tethering)
- Re-run `adb-usb-p` after unplugging or WSL restart

## Android builds from WSL
- Use `android-gradle <task>` (in `~/.scripts/`, from home repo) to build Android projects from WSL
- Must be run from the project root (where `gradlew.bat` lives)
- Example: `android-gradle assembleDebug`, `android-gradle connectedAndroidTest`
- Defaults to Android Studio's bundled JBR and `C:\Users\enshi\AppData\Local\Android\Sdk`; override via `ANDROID_JAVA_HOME` / `ANDROID_SDK_HOME`

## Flutter builds from WSL
- Use full path: `/snap/bin/flutter build apk --debug` (Bash tool doesn't source .zshrc)
- WSL-native Android SDK (`~/android-sdk/`) only has x86_64 NDK toolchains — default builds are x86_64 only
- **Pixel 9 Pro is arm64-v8a**: always pass `--target-platform android-arm64` or the app installs but crashes immediately with `MissingLibraryException: Could not find 'libflutter.so'. Looked for: [arm64-v8a], but only found: [x86_64]`
- x86_64 builds still work fine for the `utakata-test` emulator (API 34, google_apis, x86_64)
- **TODO**: install arm64 NDK toolchain in `~/android-sdk/` so default builds include both ABIs and `--target-platform` flag is no longer needed
- **TODO**: add a `flutter-install` shell alias/script to `~/.scripts/` that wraps build + `adb.exe install` in one command

## VM session naming
- When starting a Claude session on a VM (especially in tmux), run `/rename` early to give it a descriptive name matching the tmux session name or the task being performed (e.g. "telegram-bridge", "auto-anki-build")

## Independence & testing
- Operate as independently as possible: implement, build, install on emulator, and verify no crash before reporting back
- For Android: use `emulator-5554` (always available) for automated verification; flag physical device or AnkiDroid-dependent steps as explicit human touchpoints
- When a phase completes, run a build + install + logcat smoke check autonomously before asking for human review
- Only pause for: visual/feel review, physical device testing, integrations requiring external apps (AnkiDroid), or architectural decisions

## Hooks
- PostToolUse/PreToolUse hooks are configured in `~/.claude/settings.local.json`
- A failing hook can block tool execution entirely — if commands silently do nothing and return "Failed to send Telegram message", the hook is the culprit
- **TODO**: make the Telegram notification hook non-blocking — wrap the send command with `|| true` so a network failure doesn't block git/adb commands

## "Doesn't work" ≠ "can't work"
- When an API or library fails uniformly, do NOT conclude it's fundamentally infeasible. Systematically vary parameters, configuration, and context before giving up.
- **Canonical example**: YouTube IFrame API in Flutter Android WebView. Multiple sessions declared it "infeasible" because every video failed with undocumented error 152. The actual fix: changing one parameter (`origin: 'https://www.youtube-nocookie.com'` instead of the default). The error was a misconfiguration, not a platform limitation.
- **Warning signs you're about to give up too early**:
  - You're about to say "this API doesn't work in this context" but you haven't varied every relevant parameter
  - The API works in *some* context (e.g. browser) but not yours — that proves the protocol works, so the issue is configuration
  - You're pattern-matching "uniform failure" → "blocked" instead of "uniform failure" → "shared misconfiguration"
  - You found sparse/contradictory forum posts and are treating absence of a documented solution as proof there is none
  - A previous session already labeled it "infeasible" and you're inheriting that conclusion without re-investigating
- **What to do instead**: treat it as a parameter search problem. List every configurable option. Test each one. The fix is often one flag away.

## Reflection & self-improvement
- After completing a significant session, update project MEMORY.md and this file with stable learnings
- Correct stale memories immediately when discovered — don't carry forward wrong state
- When setting up infra or scripts: verify env vars and tool paths non-interactively before running; prefer idempotent scripts; verify each step succeeded before proceeding
- Avoid `set -euo pipefail` combined with `yes | <cmd>` — the broken pipe causes silent script exit; use `|| true` instead
- Check group membership before running commands that need it (e.g. `kvm` group for Android emulator); new group membership requires a new SSH session
- Verify `compileSdk` / SDK version assumptions before assuming which SDK packages are installed
- Flag secret/token exposure proactively when it appears in tool output
- Split commits by logical concern — don't bundle unrelated changes
- GCE startup scripts run as root with no `SUDO_USER` — use a hardcoded or detected `DEV_USER` instead
- `avdmanager` does not accept `--sdk_root`; use `ANDROID_SDK_ROOT` env var instead
- Deploy keys require admin repo access — collaborators must use HTTPS token auth (`~/.git-credentials`)
- `snap install` for filesystem-access tools (gcloud, gh) requires `--classic`; `/snap/bin` is not in PATH by default — add to `.zshrc`
- GCE VMs need `--scopes=cloud-platform` to call GCP APIs (Secret Manager, etc.); default scopes are too narrow — set via `gcloud compute instances set-service-account --scopes=cloud-platform` (requires VM stop/start)
- On GCE VMs, prefer fetching secrets via metadata server REST API rather than `gcloud secrets` CLI — the CLI token can be stale after scope changes

## Commit messages
- Title (1-liner) should describe the functional/user-facing change at a high level, not implementation details
  - Good: "Make small-scale deck import w/ image and scheduling work"
  - Bad: "Add zstd decompression for media files and Room migration v12→v13"
- Implementation details belong in the commit body as bullet points
- Exception: purely non-user-facing commits (refactors, test additions, CI changes) can use implementation-focused titles

## Git worktree pattern
- Repos use bare + worktree structure matching `~/local/github.com/trironkk/auto-anki/`:
  - `.bare/` — git internals
  - `.git` — file containing `gitdir: ./.bare`
  - `<branch>/` — worktrees as top-level siblings (e.g. `main/`, `master/`)
- Always ask about desired repo structure before setting one up
