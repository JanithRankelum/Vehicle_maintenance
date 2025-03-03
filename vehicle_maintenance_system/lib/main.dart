import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_vehicle/screens/splash_screen.dart';
import 'package:dr_vehicle/screens/login_screen.dart'; // Import the LoginScreen
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Import flutter_blue_plus
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
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
        visualDensity: VisualDensity.adaptivePlatformDensity, // Adaptive density for different platforms
      ),
      home: const SplashScreen(), // Set SplashScreen as the first screen
      routes: {
        '/login_screen': (context) => const LoginScreen(), // Define the login screen route
      },
      onUnknownRoute: (settings) {
        // Fallback for unknown routes
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

// Function to scan for Bluetooth devices
Future<void> scanForDevices() async {
  // FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  // Request permissions
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.locationWhenInUse.request(); // Needed for Android

  if (await Permission.bluetoothScan.isGranted &&
      await Permission.bluetoothConnect.isGranted &&
      await Permission.locationWhenInUse.isGranted) {
    // Start scanning
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // Listen for devices
    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        print("Found Device: ${result.device.name} - ${result.device.id}");
      }
    });
  } else {
    print("Permissions not granted");
  }
}