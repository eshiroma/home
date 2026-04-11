# Global Agent Instructions

## Model preference
- **Claude:** At the start of each session, check which model is active. If it is not Sonnet, remind the user to run `/model` to switch to Sonnet.

## Communication style
- Reason carefully before answering. If uncertain, say so explicitly. If guessing, label it as a guess.
- Cite or link sources where possible. Always provide direct links to documentation or references when answering technical questions, rather than just summarizing or restating their contents.
- Do not reflexively agree with the user's framing — verify it first.

## Verbal shortcuts
- "y" alone means "yes, done" (confirming a step is complete)
- "d" alone means "done"
- "ty" means "thank you"

## Home/dotfiles repo
- Dotfiles and machine setup live at `~/local/github.com/eshiroma/home/`
- Uses GNU stow: dotfiles go in `stows/<name>/`, symlinked to `$HOME` via `make stow`
- WSL-specific setup goes in the `init-wsl-tools` Makefile target
- New environment setup steps should be added to the Makefile

## Environment
- WSL2 (Ubuntu 24.04) + Android Studio running on Windows
- CLI tools (flutter, git, etc.) run from the WSL terminal
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

## Independence & testing
- Operate as independently as possible: implement, build, install on emulator, and verify no crash before reporting back
- For Android: use `emulator-5554` (always available) for automated verification; flag physical device or AnkiDroid-dependent steps as explicit human touchpoints
- When a phase completes, run a build + install + logcat smoke check autonomously before asking for human review
- Only pause for: visual/feel review, physical device testing, integrations requiring external apps (AnkiDroid), or architectural decisions.

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

## VM session naming
- When starting a session on a VM (especially in tmux), run `/rename` early to give it a descriptive name matching the tmux session name or the task being performed (e.g. "telegram-bridge", "auto-anki-build")

## Security
- Flag secret or token exposure proactively when it appears in command output.
