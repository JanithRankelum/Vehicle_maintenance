import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OBDService {
  Future<int> fetchOBDMileage() async {
    FlutterBluePlus flutterBlue = FlutterBluePlus();

    try {
      List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;
      if (devices.isEmpty) throw Exception("No OBD-II device found!");

      BluetoothDevice obdDevice = devices.first;
      List<int> command = [0x01, 0x31]; // Example OBD-II command for mileage
      BluetoothCharacteristic? characteristic;

      await obdDevice.connect();
      var services = await obdDevice.discoverServices();
      
      for (var service in services) {
        for (var chara in service.characteristics) {
          if (chara.properties.read) {
            characteristic = chara;
          }
        }
      }

      if (characteristic == null) throw Exception("No readable characteristic found!");

      await characteristic.write(command);
      List<int> response = await characteristic.read();
      
      int mileage = response[3] * 256 + response[4]; // Convert to mileage value
      return mileage;
    } catch (e) {
      print("OBD-II Error: $e");
      return -1; // If error, return -1 (indicates no OBD-II support)
    }
  }
}
