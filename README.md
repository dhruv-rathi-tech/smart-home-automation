# Smart Home Automation System

A Bluetooth-based smart home automation project combining an **8051 microcontroller**, **HC-05 Bluetooth module**, and a **Flutter Android application**.

The Flutter app sends short ASCII commands over Bluetooth. The HC-05 forwards those bytes over UART to the 8051, which controls three LEDs, a relay, and a servo motor.

## Demonstration

https://github.com/user-attachments/assets/72f2cd24-27c8-42e4-bc4e-239b8bce3424

## Architecture

```text
Flutter Android App
        |
        | Bluetooth Classic / RFCOMM
        v
      HC-05
        |
        | UART 9600, 8N1
        v
    AT89S52 / 8051
    |      |       |
  LEDs   Relay    Servo
```

## Repository layout

```text
smart-home-automation/
├── app/
│   └── smart_home_app/          # Complete Flutter application
├── firmware/
│   └── 8051/
│       └── src/main.c           # Embedded C firmware
├── docs/
│   ├── command-protocol.md
│   ├── setup-guide.md
│   └── hardware-connections.md
├── hardware/
├── .gitignore
├── LICENSE
└── README.md
```

## Hardware

| Component | Purpose |
|---|---|
| AT89S52 / compatible 8051 | Main controller |
| HC-05 | Bluetooth Classic serial link |
| 3 LEDs | Light outputs |
| Relay module | Appliance/fan switching |
| Servo motor | Position control |
| 11.0592 MHz crystal | UART timing |

### Firmware pin map

| Pin | Function |
|---|---|
| P2.1 | LED 1 |
| P2.4 | LED 2 |
| P2.7 | LED 3 |
| P1.0 | Relay |
| P1.6 | Servo |
| RXD/TXD | HC-05 UART |

**Hardware safety:** use an appropriate relay module/driver and isolation for mains-powered loads. Do not connect mains voltage directly to the 8051 or breadboard.

## Command protocol

| Byte | Action |
|---|---|
| `1` | Toggle LED 1 |
| `2` | Toggle LED 2 |
| `3` | Toggle LED 3 |
| `R` | Toggle relay |
| `0` | Servo 0° |
| `9` | Servo 90° |
| `A` | Increase servo position |
| `B` | Decrease servo position |

The firmware sends status strings ending in CR/LF. The Flutter app displays received status messages.

## Run the Flutter app

Open:

```text
app/smart_home_app
```

Then:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Pair the HC-05 in Android Bluetooth settings first.

Default first-launch password:

```text
1234
```

## Build an APK

After installing Flutter and Android SDK:

```bash
cd app/smart_home_app
flutter pub get
flutter build apk --release
```

The generated APK is intentionally **not stored in Git**. It can be rebuilt from source.

## Firmware

Open:

```text
firmware/8051/src/main.c
```

Build it with a suitable 8051 toolchain such as Keil µVision and flash the generated firmware to the controller.

The firmware expects an **11.0592 MHz crystal** for the configured 9600-baud UART.

## Verification status

This repository contains the source needed to build the Flutter application and 8051 firmware. Physical hardware behavior depends on the actual wiring, programmed microcontroller, HC-05 configuration, Android device, and connected loads.

The repository should therefore be treated as **source/build ready**, not as proof that a particular physical hardware setup has been tested.

## License

MIT. See [`LICENSE`](LICENSE).

---

## Author

**Dhruv Rathi**  
GitHub: [@dhruv-rathi-tech](https://github.com/dhruv-rathi-tech)
