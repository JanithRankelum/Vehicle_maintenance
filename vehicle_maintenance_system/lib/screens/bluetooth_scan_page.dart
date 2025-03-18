import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanPage extends StatefulWidget {
  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? scanSubscription;
  BluetoothDevice? connectedDevice;
  Map<String, bool> connectingDevices = {}; // Track connection status per device

  @override
  void initState() {
    super.initState();
    enableBluetooth();
  }

  // ✅ Ensure Bluetooth is enabled
  Future<void> enableBluetooth() async {
    if (!(await FlutterBluePlus.isOn)) {
      print("🔴 Bluetooth is OFF. Requesting to turn ON...");
      await FlutterBluePlus.turnOn();
    }
  }

  // ✅ Request necessary permissions
  Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // ✅ Scan for devices
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

  // ✅ Connect to a Bluetooth device with system-level pairing
  Future<void> connectToDevice(BluetoothDevice device) async {
    String deviceId = device.id.toString();
    setState(() {
      connectingDevices[deviceId] = true;
    });

    try {
      // Step 1: Connect to the device
      print("🔗 Connecting to ${device.name}...");
      await device.connect(autoConnect: false); // Connect first
      print("✅ Connected to ${device.name}");

      // Step 2: Pair with the device (system-level pairing)
      print("🔗 Pairing with ${device.name}...");
      await device.createBond(); // Initiate system-level pairing
      print("✅ Paired with ${device.name}");

      setState(() {
        connectedDevice = device;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Connected and paired with ${device.name}")),
      );
    } catch (e) {
      print("❌ Connection or pairing failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Connection or pairing failed: $e")),
      );
    }

    // Stop showing loading after connection attempt
    setState(() {
      connectingDevices[deviceId] = false;
    });
  }

  // ✅ Disconnect from a Bluetooth device
  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      try {
        // Step 1: Remove bond (unpair) the device
        print("🔌 Removing bond with ${connectedDevice!.name}...");
        await connectedDevice!.removeBond(); // Remove bond (unpair)
        print("✅ Bond removed with ${connectedDevice!.name}");

        // Step 2: Disconnect from the device
        print("🔌 Disconnecting from ${connectedDevice!.name}...");
        await connectedDevice!.disconnect();
        print("✅ Disconnected from ${connectedDevice!.name}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🔌 Disconnected and unpaired from ${connectedDevice!.name}")),
        );

        setState(() {
          connectedDevice = null;
        });
      } catch (e) {
        print("❌ Disconnect failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Disconnect failed: $e")),
        );
      }
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