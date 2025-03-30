import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? scanSubscription;
  BluetoothDevice? connectedDevice;
  Map<String, bool> connectingDevices = {}; // Track connection status per device
  BluetoothCharacteristic? obdCharacteristic;

  @override
  void initState() {
    super.initState();
    enableBluetooth();
  }

  Future<void> enableBluetooth() async {
    if (!(await FlutterBluePlus.isOn)) {
      print("🔴 Bluetooth is OFF. Requesting to turn ON...");
      await FlutterBluePlus.turnOn();
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  void scanForDevices() async {
    print("🔍 Starting Bluetooth scan...");

    if (!await FlutterBluePlus.isAvailable || !await FlutterBluePlus.isOn) {
      print("❌ Bluetooth is OFF. Please enable it.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please enable Bluetooth manually.")),
      );
      return;
    }

    bool hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      print("❌ Permissions not granted!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Permissions not granted.")),
      );
      return;
    }

    if (!(await Permission.locationWhenInUse.serviceStatus.isEnabled)) {
      print("❌ Location services are OFF.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enable GPS for Bluetooth scanning.")),
      );
      return;
    }

    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    await FlutterBluePlus.stopScan();
    FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    scanSubscription?.cancel();
    scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      print("📡 Found ${results.length} devices");
      setState(() {
        scanResults = results;
      });
    });

    Future.delayed(Duration(seconds: 10), () async {
      await FlutterBluePlus.stopScan();
      setState(() {
        isScanning = false;
      });
      print("⏹ Scan completed.");
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    String deviceId = device.id.toString();
    setState(() {
      connectingDevices[deviceId] = true;
    });

    try {
      print("🔗 Connecting to ${device.name}...");
      await device.connect(autoConnect: false);
      print("✅ Connected to ${device.name}");

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write && characteristic.properties.read) {
            print("✅ Found writable characteristic: ${characteristic.uuid}");

            obdCharacteristic = characteristic;
            await sendObdCommand("010C"); // Read Engine RPM
            setState(() {
              connectedDevice = device;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("✅ Connected & OBD-II Ready!")),
            );
            return;
          }
        }
      }

      print("❌ No suitable OBD-II characteristic found");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ No OBD-II characteristic found")),
      );
    } catch (e) {
      print("❌ Connection failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Connection failed: $e")),
      );
    }

    setState(() {
      connectingDevices[deviceId] = false;
    });
  }

  Future<void> sendObdCommand(String command) async {
    if (obdCharacteristic == null) {
      print("❌ No OBD-II characteristic available!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ No OBD-II characteristic available!")),
      );
      return;
    }

    try {
      List<int> obdCommand = utf8.encode("$command\r");
      await obdCharacteristic!.write(obdCommand, withoutResponse: true);
      await Future.delayed(Duration(milliseconds: 200));

      List<int> response = await obdCharacteristic!.read();
      String responseStr = utf8.decode(response);
      print("📊 OBD-II Response: $responseStr");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📊 OBD-II Response: $responseStr")),
      );
    } catch (e) {
      print("❌ Failed to send OBD-II command: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to send OBD-II command: $e")),
      );
    }
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        obdCharacteristic = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Device disconnected")),
      );
    }
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan & Connect OBD-II")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: scanForDevices,
            child: Text(isScanning ? "Scanning..." : "Scan for Devices"),
          ),
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Text(
                      isScanning ? "🔍 Scanning..." : "No devices found",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final device = scanResults[index].device;
                      String deviceId = device.id.toString();
                      bool isDeviceConnecting = connectingDevices[deviceId] ?? false;

                      return ListTile(
                        title: Text(
                          device.name.isNotEmpty ? device.name : "Unnamed Device",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(device.id.toString()),
                        trailing: connectedDevice?.id == device.id
                            ? ElevatedButton(
                                onPressed: disconnectDevice,
                                child: Text("Disconnect"),
                              )
                            : ElevatedButton(
                                onPressed: isDeviceConnecting ? null : () => connectToDevice(device),
                                child: isDeviceConnecting
                                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text("Connect"),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}