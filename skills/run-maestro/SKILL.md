---
name: run-maestro
description: Run Maestro UI test flows for auto-anki against the emulator and capture screenshots
argument-hint: [flow-file]
---

Maestro flows live in `maestro/` in the auto-anki repo. The emulator (`emulator-5554`) is the standard target.

## Prerequisites

Maestro binary is at `~/.maestro/bin/maestro` (not in PATH by default in non-interactive shells).

```bash
export PATH="$PATH:$HOME/.maestro/bin"
```

App must already be installed. If not, run `/android-build-install` first.

## Run a specific flow

```bash
cd /mnt/c/Users/enshi/local/github.com/trironkk/auto-anki/master
~/.maestro/bin/maestro test maestro/smoke_test.yaml
```

## Run all flows

```bash
~/.maestro/bin/maestro test maestro/
```

## Screenshots

Flows use `takeScreenshot: screenshots/<name>` — output lands in `maestro/screenshots/` (gitignored).

To promote a screenshot to golden reference:
```bash
cp maestro/screenshots/<name>.png maestro/golden/<name>.png
git add maestro/golden/<name>.png
```

To upload screenshots to GCS for remote review:
```bash
gsutil cp maestro/screenshots/*.png gs://auto-anki-maestro-screenshots/
```

## Troubleshooting

- **"maestro: command not found"**: use full path `~/.maestro/bin/maestro` or export PATH above
- **Flow times out waiting for element**: app may have crashed — run `/logcat-crash` to check
- **Emulator not connected**: run `adb-emulator` (`adb connect localhost:5555`), then retry
- **Screenshots landing at repo root**: flows missing `screenshots/` prefix in `takeScreenshot` — update path in yaml
