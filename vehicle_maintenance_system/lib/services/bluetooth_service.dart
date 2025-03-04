import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Scan for Bluetooth devices
  void scanForDevices(Function(List<ScanResult>) onScanResults) async {
    if (!await FlutterBluePlus.isAvailable || !await FlutterBluePlus.isOn) {
      print("❌ Bluetooth is unavailable or turned off.");
      return;
    }

    stopScan(); // Stop previous scans if running

    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    // Listen for scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      onScanResults(results);
    });
  }

  // Connect to an OBD-II device
  Future<void> connectToObd(BluetoothDevice obdDevice) async {
    try {
      if (obdDevice.isConnected) {
        print("⚠️ Already connected to ${obdDevice.name}");
        return;
      }

      await obdDevice.connect();
      print("✅ Connected to OBD-II Device: ${obdDevice.name}");
    } catch (e) {
      print("❌ Connection Failed: $e");
      rethrow; // Let UI handle errors
    }
  }

  // Stop scanning
  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  // Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    return await FlutterBluePlus.isAvailable;
  }

  // Turn on Bluetooth if off (⚠️ Not supported on iOS)
  Future<void> turnOnBluetooth() async {
    if (!await FlutterBluePlus.isOn) {
      print("⚠️ Please turn on Bluetooth manually.");
    }
  }

  // Dispose method to clean up streams
  void dispose() {
    stopScan();
  }
}
