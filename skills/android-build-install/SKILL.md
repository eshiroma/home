---
name: android-build-install
description: Build and install Android apps (auto-anki, utakata) on Pixel 7/9 Pro or emulator from WSL
argument-hint: [device] [build-type]
---

Build and/or install an Android app on the requested target device. Follow the steps below in order.

## Step 1: Check what's already connected

```bash
adb devices
```

If the target device is already listed and online, skip to Step 3 (Build).

## Step 2: Connect the device

### Emulator
The emulator (`emulator-5554`) auto-starts on boot. If it's not listed:
```bash
adb-emulator   # alias: adb connect localhost:5555
```

### Pixel 7 Pro (primary dev device)

**USB (most reliable):**
```bash
adb-usb-p7     # alias: usbipd.exe attach --wsl --busid 2-6
```
Re-run after unplugging or WSL restart. One-time setup (admin PowerShell): `usbipd bind --busid 2-6`.

**Wireless via Tailscale:**
```bash
adb-p7         # alias: adb -s 100.108.143.98:5555
```
Requires Tailscale active and `adb tcpip 5555` run once over USB after each device reboot.

### Pixel 9 Pro

**USB:**
```bash
adb-usb-p9     # alias: usbipd.exe attach --wsl --busid 1-5
```
One-time setup (admin PowerShell): `usbipd bind --busid 1-5`.

**Wireless via Tailscale:**
```bash
adb-p9         # alias: adb.exe -s 100.100.163.108:36977
```
Requires `adb tcpip 36977` run once over USB after each device reboot.

Verify connection:
```bash
adb devices
```

## Step 3: Build the APK

### auto-anki (Kotlin/Gradle)
Run from the worktree root (e.g. `master/`) where `gradlew.bat` lives:
```bash
cd /mnt/c/Users/enshi/local/github.com/trironkk/auto-anki/master
android-gradle assembleDebug
```
APK output: `app/build/outputs/apk/debug/app-debug.apk`

For instrumented tests on emulator:
```bash
android-gradle connectedAndroidTest
```

### utakata (Flutter)
Run from the worktree root:
```bash
cd /mnt/c/Users/enshi/local/github.com/eshiroma/utakata/main
/snap/bin/flutter build apk --debug
```
APK output: `build/app/outputs/flutter-apk/app-debug.apk`

**Pixel 9 Pro requires arm64 target** (WSL-native SDK only has x86_64 NDK):
```bash
/snap/bin/flutter build apk --debug --target-platform android-arm64
```
Without this flag, the app installs but crashes immediately with `MissingLibraryException: Could not find 'libflutter.so'`.

**Install utakata on emulator:**
```bash
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Install utakata on Pixel 9 Pro (wireless):**
```bash
adb.exe -s $PIXEL_9_PRO install -r $(wslpath -w build/app/outputs/flutter-apk/app-debug.apk)
```

## Step 4: Install the APK

Use the correct `adb` variant based on device connection type:

### Emulator (emulator-5554)
```bash
adb -s emulator-5554 install -r app/build/outputs/apk/debug/app-debug.apk
```

### Pixel 7 Pro (wireless — uses native WSL adb)
```bash
adb -s $PIXEL_7_PRO install -r app/build/outputs/apk/debug/app-debug.apk
```

### Pixel 9 Pro (wireless — uses adb.exe with Windows path)
```bash
adb.exe -s $PIXEL_9_PRO install -r $(wslpath -w app/build/outputs/apk/debug/app-debug.apk)
```

### USB-connected device (uses adb.exe with Windows path)
```bash
adb.exe -s <serial> install -r $(wslpath -w <apk-path>)
```
Find `<serial>` from `adb devices`.

## Quick reference

| Alias       | Expands to                                  | Notes                        |
|-------------|---------------------------------------------|------------------------------|
| `adb-usb-p` | `usbipd.exe attach --wsl --busid 2-6`       | USB attach Pixel 7 Pro       |
| `adb-p`     | `adb -s 100.108.143.98:5555`                | Wireless Pixel 7 Pro         |
| `adb-usb-p7`| `usbipd.exe attach --wsl --busid 2-6`       | Same as adb-usb-p            |
| `adb-p7`    | `adb -s 100.108.143.98:5555`                | Same as adb-p                |
| `adb-usb-p9`| `usbipd.exe attach --wsl --busid 1-5`       | USB attach Pixel 9 Pro       |
| `adb-p9`    | `adb.exe -s 100.100.163.108:36977`          | Wireless Pixel 9 Pro         |
| `adb-emulator`| `adb connect localhost:5555`              | Connect emulator             |

## Troubleshooting

- **Device not showing after `adb-usb-p7`**: re-run after unplugging/replugging or WSL restart
- **Wireless not connecting**: check Tailscale is up on both sides; run `adb tcpip <port>` over USB first
- **Flutter arm64 crash on Pixel 9 Pro**: add `--target-platform android-arm64` to the build command
- **`adb` vs `adb.exe`**: use native `adb` for wireless Pixel 7 Pro and emulator; use `adb.exe` for USB connections and Pixel 9 Pro wireless
- **Build fails "gradlew.bat not found"**: must run `android-gradle` from the worktree root, not the repo root
