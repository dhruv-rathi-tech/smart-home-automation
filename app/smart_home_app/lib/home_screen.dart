import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final BluetoothConnection connection;

  const HomeScreen({super.key, required this.connection});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _led1 = false;
  bool _led2 = false;
  bool _led3 = false;
  bool _relay = false;
  bool _isConnected = true;
  bool _isDarkTheme = true;
  bool _isListening = false;
  int _servoAngle = 90;

  String _statusLog = 'Connected to HC-05';
  String _lastCommand = 'None';
  String _lastCommandTime = '--:--';
  String _voiceText = 'Tap the microphone and speak';

  int _toggleCount = 0;

  late final stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    widget.connection.input?.listen((data) {
      final message = ascii.decode(data, allowInvalid: true).trim();
      if (!mounted || message.isEmpty) return;
      setState(() {
        _statusLog = '8051: $message';
        _isConnected = true;
      });
    }, onDone: () {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _statusLog = 'Bluetooth connection closed';
        });
      }
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _statusLog = 'Bluetooth connection error';
        });
      }
    });
  }

  void _sendCommand(String command, String description) {
    try {
      widget.connection.output.add(ascii.encode(command));
      final now = TimeOfDay.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');

      setState(() {
        _isConnected = true;
        _lastCommand = description;
        _lastCommandTime = '$hour:$minute';
        _statusLog = 'Sent "$command" — $description';
      });
    } catch (_) {
      setState(() {
        _isConnected = false;
        _statusLog = 'Unable to send command';
      });
    }
  }

  void _toggleLed(int led) {
    setState(() {
      if (led == 1) _led1 = !_led1;
      if (led == 2) _led2 = !_led2;
      if (led == 3) _led3 = !_led3;
      _toggleCount++;
    });
    _sendCommand('$led', 'LED $led ${_ledState(led) ? "ON" : "OFF"}');
  }

  bool _ledState(int led) {
    if (led == 1) return _led1;
    if (led == 2) return _led2;
    return _led3;
  }

  void _toggleRelay() {
    setState(() {
      _relay = !_relay;
      _toggleCount++;
    });
    _sendCommand('R', 'Relay ${_relay ? "ON" : "OFF"}');
  }

  void _setServo(int angle) {
    final clamped = angle.clamp(0, 180);
    final command = clamped == 0
        ? '0'
        : clamped == 90
            ? '9'
            : null;

    setState(() => _servoAngle = clamped);

    if (command != null) {
      _sendCommand(command, 'Servo set to $clamped°');
      return;
    }

    // Firmware changes one step per A/B command. Send the minimum
    // number of commands needed to reach the requested angle.
    final delta = clamped - 90;
    final stepCommand = delta > 0 ? 'A' : 'B';
    final steps = delta.abs();

    for (var i = 0; i < steps; i++) {
      widget.connection.output.add(ascii.encode(stepCommand));
    }

    final now = TimeOfDay.now();
    setState(() {
      _lastCommand = 'Servo set to $clamped°';
      _lastCommandTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _statusLog = 'Sent $steps servo step command(s)';
    });
  }

  void _servoStep(int delta) {
    final target = (_servoAngle + delta).clamp(0, 180);
    if (target == _servoAngle) return;

    final command = delta > 0 ? 'A' : 'B';
    widget.connection.output.add(ascii.encode(command));
    setState(() {
      _servoAngle = target;
      _lastCommand = 'Servo ${target}°';
      _statusLog = 'Sent "$command"';
    });
  }

  void _allOff() {
    if (_led1) _toggleLed(1);
    if (_led2) _toggleLed(2);
    if (_led3) _toggleLed(3);
    if (_relay) _toggleRelay();

    setState(() => _lastCommand = 'All devices turned OFF');
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _voiceText = 'Voice error: ${error.errorMsg}';
          });
        }
      },
    );

    if (!available) {
      setState(() => _voiceText = 'Speech recognition is unavailable');
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _voiceText = result.recognizedWords);

        if (result.finalResult) {
          _processVoiceCommand(result.recognizedWords.toLowerCase());
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processVoiceCommand(String command) {
    if (command.contains('all off') ||
        command.contains('everything off')) {
      _allOff();
      setState(() => _voiceText = 'All devices OFF');
      return;
    }

    if (command.contains('all on') || command.contains('everything on')) {
      if (!_led1) _toggleLed(1);
      if (!_led2) _toggleLed(2);
      if (!_led3) _toggleLed(3);
      if (!_relay) _toggleRelay();
      setState(() => _voiceText = 'All devices ON');
      return;
    }

    if (command.contains('light 1 on') ||
        command.contains('light one on') ||
        command.contains('turn on light one')) {
      if (!_led1) _toggleLed(1);
      setState(() => _voiceText = 'Light 1 ON');
    } else if (command.contains('light 1 off') ||
        command.contains('light one off') ||
        command.contains('turn off light one')) {
      if (_led1) _toggleLed(1);
      setState(() => _voiceText = 'Light 1 OFF');
    } else if (command.contains('light 2 on') ||
        command.contains('light two on')) {
      if (!_led2) _toggleLed(2);
      setState(() => _voiceText = 'Light 2 ON');
    } else if (command.contains('light 2 off') ||
        command.contains('light two off')) {
      if (_led2) _toggleLed(2);
      setState(() => _voiceText = 'Light 2 OFF');
    } else if (command.contains('light 3 on') ||
        command.contains('light three on')) {
      if (!_led3) _toggleLed(3);
      setState(() => _voiceText = 'Light 3 ON');
    } else if (command.contains('light 3 off') ||
        command.contains('light three off')) {
      if (_led3) _toggleLed(3);
      setState(() => _voiceText = 'Light 3 OFF');
    } else if (command.contains('light on')) {
      if (!_led1) _toggleLed(1);
      setState(() => _voiceText = 'Light 1 ON');
    } else if (command.contains('light off')) {
      if (_led1) _toggleLed(1);
      setState(() => _voiceText = 'Light 1 OFF');
    } else if (command.contains('fan on') ||
        command.contains('turn on fan') ||
        command.contains('relay on')) {
      if (!_relay) _toggleRelay();
      setState(() => _voiceText = 'Relay ON');
    } else if (command.contains('fan off') ||
        command.contains('turn off fan') ||
        command.contains('relay off')) {
      if (_relay) _toggleRelay();
      setState(() => _voiceText = 'Relay OFF');
    } else if (command.contains('servo zero') ||
        command.contains('servo 0') ||
        command.contains('servo off')) {
      _setServo(0);
      setState(() => _voiceText = 'Servo 0°');
    } else if (command.contains('servo ninety') ||
        command.contains('servo 90')) {
      _setServo(90);
      setState(() => _voiceText = 'Servo 90°');
    } else {
      setState(() => _voiceText = 'Not recognized: "$command"');
    }
  }

  void _changePassword(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('app_password', controller.text);

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    widget.connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Home'),
          actions: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 11,
                  color: _isConnected ? Colors.greenAccent : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(_isConnected ? 'Live' : 'Lost'),
                const SizedBox(width: 4),
              ],
            ),
            IconButton(
              icon: Icon(
                _isDarkTheme ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () => setState(() => _isDarkTheme = !_isDarkTheme),
            ),
            PopupMenuButton<String>(
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'password',
                  child: Text('Change Password'),
                ),
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
              onSelected: (value) {
                if (value == 'password') _changePassword(context);
                if (value == 'logout') {
                  widget.connection.dispose();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statusCard(),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard('Actions', _toggleCount),
                  const SizedBox(width: 12),
                  _statCard('Servo', _servoAngle),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Devices',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _controlTile(
                'Light 1',
                Icons.lightbulb,
                _led1,
                () => _toggleLed(1),
                Colors.amber,
                'P2.1 • Command 1',
              ),
              const SizedBox(height: 10),
              _controlTile(
                'Light 2',
                Icons.lightbulb,
                _led2,
                () => _toggleLed(2),
                Colors.orange,
                'P2.4 • Command 2',
              ),
              const SizedBox(height: 10),
              _controlTile(
                'Light 3',
                Icons.lightbulb,
                _led3,
                () => _toggleLed(3),
                Colors.yellow,
                'P2.7 • Command 3',
              ),
              const SizedBox(height: 10),
              _controlTile(
                'Fan / Relay',
                Icons.wind_power,
                _relay,
                _toggleRelay,
                Colors.blue,
                'P1.0 • Command R',
              ),
              const SizedBox(height: 16),
              _servoCard(),
              const SizedBox(height: 16),
              _voiceCard(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _allOff,
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('ALL OFF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _lastCommand,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text('Last action: $_lastCommandTime'),
          const SizedBox(height: 5),
          Text(_statusLog),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlTile(
    String label,
    IconData icon,
    bool isOn,
    VoidCallback onTap,
    Color color,
    String subtitle,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: isOn ? color : Colors.grey),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: isOn,
          onChanged: (_) => onTap(),
        ),
      ),
    );
  }

  Widget _servoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Servo Motor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('P1.6 • Current position: $_servoAngle°'),
            const SizedBox(height: 12),
            Slider(
              value: _servoAngle.toDouble(),
              min: 0,
              max: 180,
              divisions: 180,
              label: '$_servoAngle°',
              onChanged: (value) => setState(() => _servoAngle = value.round()),
              onChangeEnd: (value) => _setServo(value.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => _setServo(0),
                  child: const Text('0°'),
                ),
                OutlinedButton(
                  onPressed: () => _setServo(90),
                  child: const Text('90°'),
                ),
                IconButton(
                  onPressed: () => _servoStep(-1),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () => _servoStep(1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton.filled(
              onPressed: _isListening ? _stopListening : _startListening,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              tooltip: _isListening ? 'Stop' : 'Voice command',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isListening ? 'Listening...' : 'Voice Control',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_voiceText),
                  const SizedBox(height: 4),
                  const Text(
                    'Try: "light one on", "fan off", "servo 90"',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
