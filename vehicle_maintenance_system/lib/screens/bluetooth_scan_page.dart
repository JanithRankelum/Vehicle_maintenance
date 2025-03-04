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

  @override
  void initState() {
    super.initState();
    listenToBluetoothState();
  }

  Future<void> checkAndEnableBluetooth() async {
    if (!await FlutterBluePlus.isAvailable) {
      print("❌ Bluetooth is not available on this device.");
      return;
    }

    if (!await FlutterBluePlus.isOn) {
      print("⚠️ Bluetooth is off. Please enable it manually.");
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

  void listenToBluetoothState() {
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        print("✅ Bluetooth is ON. Ready to scan.");
      } else {
        print("❌ Bluetooth is OFF. Please enable it.");
      }
    });
  }

  void scanForDevices() async {
    // Ensure Bluetooth is available and ON
    if (!await FlutterBluePlus.isAvailable || !await FlutterBluePlus.isOn) {
      print("❌ Bluetooth is not available or OFF.");
      return;
    }

    // Request permissions
    bool hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permissions not granted")),
      );
      return;
    }

    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    // Start scanning
    FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    // Avoid multiple subscriptions
    scanSubscription?.cancel();
    scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      setState(() {
        scanResults = results;
      });
    });

    // Stop scanning after 10 seconds
    Future.delayed(Duration(seconds: 10), () async {
      await FlutterBluePlus.stopScan();
      setState(() {
        isScanning = false;
      });
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan OBD-II Devices")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              await checkAndEnableBluetooth();
              scanForDevices();
            },
            child: Text(isScanning ? "Scanning..." : "Scan for Devices"),
          ),
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Text(
                      isScanning ? "🔍 Scanning for devices..." : "No devices found",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final device = scanResults[index].device;
                      return ListTile(
                        title: Text(
                          device.name.isNotEmpty ? device.name : "Unknown Device",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(device.id.toString()),
                        trailing: Icon(Icons.bluetooth),
                        onTap: () {
                          // Handle device connection
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
