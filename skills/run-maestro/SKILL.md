---
name: run-maestro
description: Run Maestro UI test flows for auto-anki or utakata against the emulator and capture screenshots
argument-hint: [project] [flow-file]
---

Maestro flows live in `maestro/` in each repo. The emulator (`emulator-5554`) is the standard target.

## Prerequisites

Maestro binary is at `~/.maestro/bin/maestro` (not in PATH by default in non-interactive shells).

```bash
export PATH="$PATH:$HOME/.maestro/bin"
```

App must already be installed. If not, run `/android-build-install` first.

## auto-anki

Run a specific flow:
```bash
cd /mnt/c/Users/enshi/local/github.com/trironkk/auto-anki/master
~/.maestro/bin/maestro test maestro/smoke_test.yaml
```

Run all flows:
```bash
~/.maestro/bin/maestro test maestro/
```

Upload screenshots to GCS for remote review:
```bash
gsutil cp maestro/screenshots/*.png gs://auto-anki-maestro-screenshots/
```

## utakata

Run a specific flow:
```bash
cd /mnt/c/Users/enshi/local/github.com/eshiroma/utakata/main
~/.maestro/bin/maestro test maestro/song_list_basics.yaml
```

Run all flows:
```bash
~/.maestro/bin/maestro test maestro/
```

Key flows and what they cover:

| Flow | Covers |
|------|--------|
| `song_list_basics.yaml` | Song list renders, basic navigation |
| `paste_lyrics_flow.yaml` | Paste + parse lyrics end-to-end |
| `paste_and_edit_lyrics.yaml` | Edit lyrics after pasting |
| `play_video.yaml` | YouTube video playback |
| `transport_controls.yaml` | Play/pause/seek controls |
| `edit_line_dialog.yaml` | Line editing dialog |
| `edit_song_title.yaml` | Song title editing |
| `shift_timestamps.yaml` | Timestamp adjustment |
| `font_size.yaml` | Font size setting |
| `overflow_menu.yaml` | Overflow menu actions |
| `delete_song.yaml` | Song deletion |
| `song_persistence.yaml` | Songs persist after restart |
| `export_word_test.yaml` | Word export feature |
| `scan_screenshots_song_list.yaml` | Screenshot scan (song list) |
| `scan_screenshots_edit_mode.yaml` | Screenshot scan (edit mode) |
| `ai_align_ui.yaml` | AI alignment UI |
| `dismiss_16kb_dialog.yaml` | 16KB page size dialog |

## Screenshots

Flows use `takeScreenshot: screenshots/<name>` — output lands in `maestro/screenshots/` (gitignored).

To promote a screenshot to golden reference:
```bash
cp maestro/screenshots/<name>.png maestro/golden/<name>.png
git add maestro/golden/<name>.png
```

## Troubleshooting

- **"maestro: command not found"**: use full path `~/.maestro/bin/maestro` or export PATH above
- **Flow times out waiting for element**: app may have crashed — run `/logcat-crash` to check
- **Emulator not connected**: run `adb-emulator` (`adb connect localhost:5555`), then retry
- **Screenshots landing at repo root**: flows missing `screenshots/` prefix in `takeScreenshot` — update path in yaml
