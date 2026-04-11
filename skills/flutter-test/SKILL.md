---
name: flutter-test
description: Run unit, widget, and integration tests for utakata (Flutter); covers emulator setup for integration tests
argument-hint: [unit|integration|all]
---

utakata has three test layers. Run from the project root:
```bash
cd /mnt/c/Users/enshi/local/github.com/eshiroma/utakata/main
```

## Unit and widget tests (no device needed)

```bash
/snap/bin/flutter test
```

Runs all tests in `test/`: `ruby_text_test.dart`, `widget_test.dart`, `app_test.dart`, `screenshot_test.dart`.

Run a single file:
```bash
/snap/bin/flutter test test/app_test.dart
```

## Integration tests (requires emulator)

Integration tests live in `integration_test/`. The emulator (`utakata-test` AVD, `emulator-5554`) must be running.

Verify emulator is connected:
```bash
adb devices   # should show emulator-5554
```

If not connected:
```bash
adb-emulator   # alias: adb connect localhost:5555
```

Run all integration tests:
```bash
/snap/bin/flutter test integration_test/
```

Run a single integration test:
```bash
/snap/bin/flutter test integration_test/app_test.dart
```

## Emulator first-time setup (WSL, one-time)

If `utakata-test` AVD doesn't exist yet:

```bash
export ANDROID_SDK_ROOT=~/android-sdk
$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager \
  "system-images;android-34;google_apis;x86_64" \
  "emulator" "platform-tools"

$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager create avd \
  --name utakata-test \
  --package "system-images;android-34;google_apis;x86_64" \
  --device "pixel_6" \
  --force
```

Launch headless:
```bash
$ANDROID_SDK_ROOT/emulator/emulator \
  -avd utakata-test -no-window -no-audio -no-boot-anim \
  -gpu swiftshader_indirect &
adb wait-for-device
```

Check KVM access first — required for x86_64 emulator:
```bash
id -nG | grep kvm   # must appear; if not: sudo usermod -aG kvm $USER + new SSH session
ls -l /dev/kvm
```

## Troubleshooting

- **"No devices found"**: emulator not running or not connected — run `adb-emulator`
- **KVM permission denied**: add to kvm group (`sudo usermod -aG kvm $USER`), then start a new SSH session (newgrp alone is insufficient)
- **Integration test times out on fixture load**: check `integration_test/fixtures/` has required test assets
- **`flutter test` uses wrong SDK**: use full path `/snap/bin/flutter` in non-interactive shells (PATH not sourced from .zshrc)
