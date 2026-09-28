  import 'package:flutter/material.dart';
  import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'home_screen.dart';

  class BluetoothScreen extends StatefulWidget {
    const BluetoothScreen({super.key});

    @override
    State<BluetoothScreen> createState() => _BluetoothScreenState();
  }

  class _BluetoothScreenState extends State<BluetoothScreen> {
    List<BluetoothDevice> _devices = [];
    bool _isLoading = false;

    @override
    void initState() {
      super.initState();
      _requestPermissionsAndLoad();
    }

    Future<void> _requestPermissionsAndLoad() async {
      await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();
      _loadDevices();
    }

    Future<void> _loadDevices() async {
      setState(() => _isLoading = true);
      try {
        List<BluetoothDevice> devices =
            await FlutterBluetoothSerial.instance.getBondedDevices();
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }

    Future<void> _connectToDevice(BluetoothDevice device) async {
      try {
        BluetoothConnection connection =
            await BluetoothConnection.toAddress(device.address);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(connection: connection),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Bluetooth Device'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDevices,
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _devices.isEmpty
                ? const Center(
                    child: Text(
                      'No paired devices found.\nPair HC-05 in phone Bluetooth settings first.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.name ?? 'Unknown'),
                        subtitle: Text(device.address),
                        onTap: () => _connectToDevice(device),
                      );
                    },
                  ),
      );
    }
  }