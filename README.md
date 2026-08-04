# Smart Home Automation System (8051 + Bluetooth + Flutter App)

A Bluetooth-controlled home automation system built on the **8051 microcontroller**, paired with a **Flutter mobile app** that supports **voice commands** and **manual switch control**. The app communicates with the 8051 board over Bluetooth (HC-05 module) to control lights, a relay-driven appliance, and a servo motor in real time.

---

## Features

- 🔌 **Relay control** — switch a connected appliance ON/OFF
- 💡 **3-channel LED control** — independently toggle 3 LEDs
- 🎚️ **Servo motor control** — set to preset angles (0°, 90°) or increment/decrement in steps
- 🎙️ **Voice command control** — control devices hands-free via the mobile app
- 📱 **Manual switch UI** — toggle each device directly from the app
- 🔵 **Bluetooth communication** — HC-05 module interfaced via UART at 9600 baud
- 🔁 **Real-time feedback** — 8051 sends status acknowledgements back to the app over UART

---

## System Architecture

```
┌─────────────────┐     Bluetooth (HC-05)     ┌──────────────────────┐
│  Flutter Mobile  │ ───────────────────────►  │   8051 Microcontroller │
│       App        │ ◄─────────────────────── │   (AT89S52 / similar)  │
│ (Voice + Switch) │      UART @ 9600 baud     └──────────┬───────────┘
└─────────────────┘                                       │
                                                            ▼
                                          ┌─────────────────────────────┐
                                          │ LED1 (P2.1) │ LED2 (P2.4)    │
                                          │ LED3 (P2.7) │ Relay (P1.0)   │
                                          │ Servo (P1.6)                │
                                          └─────────────────────────────┘
```

---

## Repository Structure

```
smart-home-project/
├── firmware/
│   └── 8051/
│       └── src/
│           └── main.c          # 8051 embedded C firmware (Keil/SDCC compatible)
├── app/
│   └── android/
│       └── app/
│           └── src/
│               └── main/
│                   └── AndroidManifest.xml   # App permissions (Bluetooth, Location)
├── docs/
│   └── command-protocol.md     # Serial command reference (app ↔ 8051)
├── .gitignore
├── LICENSE
└── README.md
```

> **Note:** The `app/` directory here contains only the Android manifest that was part of this repository snapshot. If you have the full Flutter project (lib/, pubspec.yaml, etc.), place it under `app/` following standard Flutter project structure — the `.gitignore` is already configured to handle Flutter/Android build artifacts correctly.

---

## Hardware Requirements

| Component | Purpose |
|---|---|
| 8051 Microcontroller (AT89S52 or similar) | Main controller |
| HC-05 Bluetooth Module | Wireless serial communication |
| 3x LEDs | Digital output indicators |
| 1x Relay Module | Appliance switching |
| 1x Servo Motor | Positional control (e.g., curtain/door) |
| 11.0592 MHz Crystal | Required for accurate 9600 baud UART timing |

### Pin Mapping

| Pin | Function |
|---|---|
| P2.1 | LED1 |
| P2.4 | LED2 |
| P2.7 | LED3 |
| P1.0 | Relay |
| P1.6 | Servo (PWM) |
| UART (TXD/RXD) | HC-05 Bluetooth Module |

---

## Serial Command Protocol

The app communicates with the 8051 over Bluetooth using single-character ASCII commands:

| Command | Action |
|---|---|
| `1` | Toggle LED1 |
| `2` | Toggle LED2 |
| `3` | Toggle LED3 |
| `R` | Toggle Relay |
| `0` | Set servo to 0° |
| `9` | Set servo to 90° |
| `A` | Increase servo angle (step) |
| `B` | Decrease servo angle (step) |

The 8051 responds with status strings (e.g. `LED1 ON`, `RELAY OFF`, `Servo at 90 degrees`) after processing each command. See [`docs/command-protocol.md`](docs/command-protocol.md) for full details.

---

## Getting Started

### 1. Firmware (8051)
1. Open `firmware/8051/src/main.c` in Keil µVision (or your preferred 8051 IDE/toolchain).
2. Set the crystal frequency to **11.0592 MHz** in the project configuration (required for accurate 9600 baud UART).
3. Build the project to generate the `.hex` file.
4. Flash the `.hex` file to your 8051 microcontroller using a programmer (e.g., USBASP, or an ISP programmer for AT89S52).
5. Wire the components per the pin mapping table above.

### 2. Mobile App
1. Ensure you have the full Flutter project source (this repo currently includes the manifest only — add `lib/`, `pubspec.yaml`, and platform folders as needed).
2. Run `flutter pub get` inside `app/` to install dependencies.
3. Connect your Android device, enable Bluetooth & Location permissions when prompted (required for Bluetooth scanning on Android).
4. Pair your phone with the HC-05 module (default PIN is usually `1234` or `0000`).
5. Run `flutter run` to build and launch the app.

---

## Permissions Used (Android)

- `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` — required to discover and connect to the HC-05 module.
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` — required by Android for Bluetooth device scanning (OS-level requirement, not used for actual location tracking).

---

## Future Improvements

- [ ] Add WiFi (ESP8266/ESP32) fallback for remote (non-local) control
- [ ] Persist device states across power cycles (EEPROM)
- [ ] Add scheduling/automation rules in the app
- [ ] iOS support

---

## License

This project is licensed under the MIT License — see [`LICENSE`](LICENSE) for details.

---

## Author

**Dhruv Rathi**
GitHub: [@dhruv-rathi-tech](https://github.com/dhruv-rathi-tech)
