import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_vehicle/screens/home_screen.dart';
import 'package:dr_vehicle/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      User? user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => user != null ? HomeScreen() : LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E0F),
      body: Center(
        child: Image.asset('assets/logo/app1.gif', width: 500), // Local GIF
      ),
    );
  }
}

