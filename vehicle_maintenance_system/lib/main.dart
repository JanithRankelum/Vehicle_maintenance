import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dr_vehicle/screens/splash_screen.dart';
import 'package:dr_vehicle/screens/login_screen.dart';
import 'package:dr_vehicle/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_vehicle/screens/info_screen.dart';
import 'package:dr_vehicle/models/service_model.dart';

// Background task handler
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Get user ID from Firestore (not from auth, since background tasks have no auth context)
      final userId = inputData?['userId']; // You need to pass this when registering the task
      if (userId == null || userId.isEmpty) return false;

      final firestoreService = FirestoreService();
      
      // Get first vehicle ID (modify this if you need to handle multiple vehicles)
      final vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(userId)
          .get();

      if (!vehicleSnapshot.exists) return false;

      await firestoreService.automateServiceUpdates(userId, vehicleSnapshot.id);
      return true;
    } catch (e) {
      print("Background task failed: $e");
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Workmanager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // Register periodic task with user ID
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    Workmanager().registerPeriodicTask(
      "serviceUpdates",
      "automateServiceUpdates",
      inputData: {'userId': currentUser.uid}, // Pass user ID to background task
      frequency: const Duration(hours: 12),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dr. Vehicle',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      routes: {
        '/login_screen': (context) => const LoginScreen(),
        '/info_screen': (context) => const InfoScreen(), // Add this route
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