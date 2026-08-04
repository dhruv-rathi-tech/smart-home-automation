# Serial Command Protocol

Communication between the Flutter app and the 8051 microcontroller happens over Bluetooth (HC-05), using UART at **9600 baud, 8N1** (8 data bits, no parity, 1 stop bit).

Each command is a **single ASCII character**. The 8051 processes it in `processCommand()` and replies with a status string terminated by `\r\n`.

## Commands (App → 8051)

| Byte Sent | Meaning | Response (8051 → App) |
|---|---|---|
| `'1'` | Toggle LED1 (P2.1) | `LED1 ON` / `LED1 OFF` |
| `'2'` | Toggle LED2 (P2.4) | `LED2 ON` / `LED2 OFF` |
| `'3'` | Toggle LED3 (P2.7) | `LED3 ON` / `LED3 OFF` |
| `'R'` | Toggle Relay (P1.0) | `RELAY ON` / `RELAY OFF` |
| `'0'` | Move servo to 0° | `Servo at 0 degrees` |
| `'9'` | Move servo to 90° | `Servo at 90 degrees` |
| `'A'` | Increment servo angle by 1 step (max 180°) | `Servo +` |
| `'B'` | Decrement servo angle by 1 step (min 0°) | `Servo -` |
| *(any other byte)* | Unrecognized | `Unknown Command` |

## Servo Position Encoding

The firmware stores `servoPosition` as an integer representing pulse width in **0.1 ms units**:

- `servoPosition = 5`  → 0.5 ms pulse → 0°
- `servoPosition = 14` → 1.4 ms pulse → ~90° (default/startup position)
- `servoPosition = 24` → 2.4 ms pulse → 180°

The `servoControl()` function generates a 50 Hz PWM signal (20 ms period) continuously in the main loop, using this value to set the high-pulse duration.

## Boot Message

On startup, the 8051 sends:
```
System Ready
```
This can be used by the app to confirm a successful Bluetooth connection and firmware readiness.

## Voice Command Mapping (App-side)

Voice commands recognized by the app should be mapped to the single-character commands above before transmission — e.g., "turn on light one" → sends `'1'`, "turn on the fan/relay" → sends `'R'`. This mapping lives in the app's voice-recognition handler, not in the firmware.
