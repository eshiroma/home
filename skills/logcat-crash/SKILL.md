---
name: logcat-crash
description: Filter logcat to crash-relevant output for auto-anki; use after every install to verify no crash on launch
argument-hint: [device]
---

Run after installing auto-anki to confirm no crash on launch. Filters to relevant tags only.

## Step 1: Clear logcat buffer

```bash
adb -s <device> logcat -c
```

Then launch the app manually or via Maestro, then proceed to Step 2.

For emulator (default):
```bash
adb -s emulator-5554 logcat -c
```

For Pixel 7 Pro (wireless):
```bash
adb -s $PIXEL_7_PRO logcat -c
```

## Step 2: Capture crash-relevant output

```bash
adb -s <device> logcat -d \
  AndroidRuntime:E \
  com.example.autoanki:* \
  GeminiHelper:* \
  FlashcardDatabase:* \
  *:F \
  *:S 2>&1 | head -100
```

- `AndroidRuntime:E` — catches Java/Kotlin exceptions and stack traces
- `*:F` — fatal signals (native crashes, SIGABRT)
- `com.example.autoanki:*` — all app logs
- `-d` — dump buffer and exit (don't tail)

## Step 3: Check for specific failure patterns

**MissingLibraryException** (Flutter arm64 on Pixel 9 Pro):
```bash
adb -s <device> logcat -d | grep -i "libflutter\|MissingLibrary"
```
Fix: rebuild with `--target-platform android-arm64`.

**Room migration failure**:
```bash
adb -s <device> logcat -d | grep -i "migration\|IllegalStateException\|room"
```

**Gemini API error**:
```bash
adb -s <device> logcat -d | grep -i "gemini\|grpc\|RESOURCE_EXHAUSTED\|INVALID_ARGUMENT"
```

## Step 4: Tail live (optional, for interactive debugging)

```bash
adb -s <device> logcat AndroidRuntime:E com.example.autoanki:* '*:S'
```

Ctrl-C to stop.

## Notes

- Use `adb.exe` instead of `adb` for USB-connected devices on WSL
- `-s emulator-5554` can be omitted if only one device is connected
- A clean launch shows no `AndroidRuntime:E` lines and app tag logs only
