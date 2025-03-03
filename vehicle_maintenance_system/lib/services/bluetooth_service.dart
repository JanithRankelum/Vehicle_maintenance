import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();

  // Method to scan for Bluetooth devices
  void scanForDevices(Function(List<ScanResult>) onScanResults) {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      onScanResults(results); // Pass results to UI
    });
  }

  // Method to connect to an OBD-II device
  Future<void> connectToObd(BluetoothDevice obdDevice) async {
    try {
      await obdDevice.connect();
      print("Connected to OBD-II Device");
    } catch (e) {
      print("Connection Failed: $e");
    }
  }

  // Stop scanning
  void stopScan() {
    FlutterBluePlus.stopScan();
  }
}
