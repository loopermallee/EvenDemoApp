# Even Demo (Android)

A native Android app that demonstrates how to pair Even G1 glasses, manage their dual-BLE
connection, and stream notification content without requiring the original Flutter shell.
The UI is written with Jetpack Compose and the low-level audio pipeline still uses the
LC3/RNNoise native library that ships with the project.

## Highlights

- **Kotlin-first implementation** – the entire runtime is implemented in Kotlin, so the
  Android module can evolve independently from the previous Flutter host.
- **Modern Compose UI** – the main screen exposes pairing, connection and debugging tools in
  a single Compose scaffold.
- **Foreground + notification services** – a background service keeps the BLE link alive and
  a notification listener forwards phone alerts to the app surface.
- **Native LC3 build** – the CMake configuration under `android/app/src/main/cpp` is wired
  into Gradle so the `liblc3.so` shared library is produced automatically during builds.

## Repository layout

```
android/                # Standalone Android Studio project
  app/
    src/main/kotlin/    # Kotlin sources
    src/main/cpp/       # LC3 / RNNoise native code
    src/main/assets/    # Reference bitmaps & fonts for Even glasses
```

Legacy Flutter files have been removed so the repository can be opened directly in Android
Studio (Giraffe or newer) without additional tooling.

## Building an APK

```bash
cd android
./gradlew assembleDebug   # or assembleRelease
```

The resulting APK will be written to `android/app/build/outputs/apk/`.

### Prerequisites

- Android Studio Giraffe (2022.3.1) or newer
- JDK 17
- Android SDK Platform 34
- NDK `25.2.9519653` (automatically downloaded by Gradle)

When running on a device you must approve the following runtime permissions:

- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`
- `ACCESS_FINE_LOCATION`
- Notification listener access (grant from Android Settings → Notifications → Notification access)

## Troubleshooting

- If you do not have notification listener access, the "Phone notifications" section on the
  home screen will explain how to enable it.
- The raw hex field in the UI accepts values such as `F5 17 00 01`. Whitespace is ignored
  and the string is automatically upper-cased before transmission.
- Logs at the bottom of the screen mirror the internal BLE manager and are limited to the
  20 most recent entries for readability.

## License

This project retains the original license from the Even Demo application. See
[LICENSE](LICENSE) for details.
