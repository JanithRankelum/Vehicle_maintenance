import 'package:flutter/material.dart';
import 'package:dr_vehicle/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_vehicle/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _user != null
                ? Column(
                    children: [
                      Text(
                        "Welcome, ${_user?.email}",
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _logout,
                        child: Text("Logout"),
                      ),
                    ],
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          ],
        ),
      ),
    );
  }
}
