import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart' as custom_bluetooth_service;

class BluetoothScanPage extends StatefulWidget {
  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final custom_bluetooth_service.BluetoothService bluetoothService =
      custom_bluetooth_service.BluetoothService();
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  void scanForDevices() async {
    setState(() {
      isScanning = true;
      scanResults.clear(); // Clear previous scan results
    });

    bluetoothService.scanForDevices((results) {
      setState(() {
        scanResults = results;
      });
    });

    // Stop scanning after 10 seconds
    await Future.delayed(Duration(seconds: 10));
    setState(() {
      isScanning = false;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await bluetoothService.connectToObd(device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to ${device.name}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan OBD-II Devices")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? null : scanForDevices,
            child: Text(isScanning ? "Scanning..." : "Start Scan"),
          ),
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Text(
                      isScanning
                          ? "Scanning for devices..."
                          : "No devices found",
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
                          connectToDevice(device); // Connect when tapped
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