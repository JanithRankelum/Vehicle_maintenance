import 'package:flutter/material.dart';
import 'package:dr_vehicle/services/auth_service.dart';
import 'package:dr_vehicle/screens/login_screen.dart';
import 'package:dr_vehicle/screens/vehicle_form_screen.dart';  // Import VehicleFormScreen

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _register() async {
    var user = await _authService.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (user != null) {
      // Navigate to VehicleFormScreen after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VehicleFormScreen()),  // Navigate to VehicleFormScreen
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Failed")),
      );
    }
  }

  void _registerWithGoogle() async {
    var user = await _authService.signInWithGoogle();
    if (user != null) {
      // Navigate to VehicleFormScreen after successful Google login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VehicleFormScreen()),  // Navigate to VehicleFormScreen
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Registration Failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text("Sign Up"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerWithGoogle,
              child: Text("Sign Up with Google"),
            ),
          ],
        ),
      ),
    );
  }
}
