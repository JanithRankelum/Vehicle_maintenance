import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestBluetoothAndLocationPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();

    return await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.locationWhenInUse.isGranted;
  }
}