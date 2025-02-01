import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_vehicle/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dr. Vehicle',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(), // Set SplashScreen as the first screen
    );
  }
}
