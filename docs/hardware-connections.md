# Hardware Connections

The firmware defines the following logical connections:

| 8051 pin | Device |
|---|---|
| P2.1 | LED 1 |
| P2.4 | LED 2 |
| P2.7 | LED 3 |
| P1.0 | Relay control input |
| P1.6 | Servo signal |
| RXD | HC-05 TX |
| TXD | HC-05 RX |

Use current-limiting resistors for LEDs and an appropriate transistor/driver or relay module where required.

The HC-05 and 8051 must share a suitable logic-level ground.

For mains appliances, use an electrically appropriate relay module, enclosure, fuse/protection, and safe isolation. Do not work on exposed mains wiring unless qualified to do so.
