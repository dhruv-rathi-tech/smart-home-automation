# Setup Guide

## 1. Flutter

Install Flutter and Android Studio/Android SDK.

```bash
cd app/smart_home_app
flutter doctor
flutter pub get
flutter analyze
flutter test
```

## 2. Android phone

1. Enable Developer Options and USB debugging if using `flutter run`.
2. Pair the HC-05 in Android Bluetooth settings.
3. Start the app.
4. Enter the default password `1234` on first launch.
5. Select the paired HC-05 device.
6. Use the device dashboard.

## 3. 8051 firmware

1. Use an 11.0592 MHz crystal.
2. Connect HC-05 TX/RX through a suitable 8051 UART interface.
3. Build `firmware/8051/src/main.c`.
4. Flash the generated firmware.
5. Power the controller.
6. The UART should transmit `System Ready`.

## 4. Functional test order

Test in this order:

1. HC-05 pairing.
2. App connects to HC-05.
3. LED 1 with command `1`.
4. LED 2 with command `2`.
5. LED 3 with command `3`.
6. Relay with command `R`.
7. Servo 0° with command `0`.
8. Servo 90° with command `9`.
9. Servo step controls with `A` / `B`.
10. Voice commands.

Do not connect an unverified relay circuit to mains voltage.
