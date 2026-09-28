# Smart Home Flutter App

Android Flutter client for the Smart Home Automation System.

## Features

- Password-protected local app entry
- Paired HC-05 device discovery and Bluetooth connection
- LED 1 / LED 2 / LED 3 controls
- Relay / fan control
- Servo control: 0°, 90°, slider and step controls
- Voice commands
- 8051 status messages
- Dark/light UI mode
- Local password storage using `shared_preferences`

## Run

Requirements:

- Flutter SDK
- Android SDK
- Android phone with Bluetooth Classic support
- Paired HC-05 module

From this directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Pair the HC-05 in Android Bluetooth settings before opening the device-selection screen.

### Default password

The first launch uses:

```text
1234
```

Change it from the app menu after login.

## Bluetooth note

The project uses `flutter_bluetooth_serial`, which targets Android Bluetooth Classic / RFCOMM. HC-05 is a Bluetooth Classic module, so this matches the intended hardware.

## Command mapping

| App action | Byte |
|---|---|
| Light 1 | `1` |
| Light 2 | `2` |
| Light 3 | `3` |
| Relay | `R` |
| Servo 0° | `0` |
| Servo 90° | `9` |
| Servo + | `A` |
| Servo - | `B` |

See the root `docs/command-protocol.md` for the complete protocol.
