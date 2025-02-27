import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_vehicle/screens/splash_screen.dart';
import 'package:dr_vehicle/screens/login_screen.dart'; // Import the LoginScreen

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
      routes: {
        '/login_screen': (context) => LoginScreen(), // Define the login screen route
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


