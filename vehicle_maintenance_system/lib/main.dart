import 'package:dr_vehicle/screens/noti_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_vehicle/screens/splash_screen.dart';
import 'package:dr_vehicle/screens/login_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestBluetoothPermissions();
  await scanForDevices();
  await NotiService().init();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dr. Vehicle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
        '/login_screen': (context) => const LoginScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}

// 🔹 Function to request and check Bluetooth & Location permissions
Future<bool> requestBluetoothPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse, // Needed for Android
  ].request();

  return statuses.values.every((status) => status.isGranted);
}

// 🔹 Function to check Bluetooth state and start scanning
Future<void> scanForDevices() async {
  // Ensure Bluetooth is available
  if (!(await FlutterBluePlus.isAvailable)) {
    print("Bluetooth is not available on this device.");
    return;
  }

  // Ensure Bluetooth is turned ON
  if (!(await FlutterBluePlus.isOn)) {
    print("Bluetooth is off. Please turn it on.");
    return;
  }

  // Request permissions
  bool hasPermissions = await requestBluetoothPermissions();
  if (!hasPermissions) {
    print("Bluetooth permissions not granted.");
    return;
  }

  // Start scanning
  FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

  // Listen for discovered devices
  FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
    for (ScanResult result in results) {
      print("Found Device: ${result.device.name} - ${result.device.id}");
    }
  });
}
