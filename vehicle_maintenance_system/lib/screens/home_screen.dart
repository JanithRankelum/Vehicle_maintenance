import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_vehicle/screens/info_screen.dart';
import 'package:dr_vehicle/screens/bluetooth_scan_page.dart';
import 'package:dr_vehicle/screens/send_obd_command_page.dart';
import 'package:dr_vehicle/screens/obd2_diagnosis_page.dart';
import 'package:dr_vehicle/screens/service_schedule_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;  // Get current user
  }

  void _logout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Logout")),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login_screen', (_) => false);
    }
  }

  Widget buildCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
        ),
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Car Image
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/logo/car.png',
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                buildCard("Vehicle Info", Icons.info_outline, Colors.blueAccent.shade700, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InfoScreen()));
                }),
                buildCard("Service Schedule", Icons.build_circle_outlined, Colors.deepPurple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceSchedulePage(vehicleData: {})));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          buildCard("OBD-II Connect", Icons.bluetooth, Colors.green.shade700, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => BluetoothScanPage()));
          }),
          buildCard("OBD2 Data", Icons.directions_car, Colors.orange.shade800, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SendObdCommandPage()));
          }),
          buildCard("OBD2 Diagnosis", Icons.warning_amber_rounded, Colors.redAccent.shade700, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => Obd2DiagnosisPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 90, color: Colors.white),
          SizedBox(height: 16),
          Text("User Profile", style: TextStyle(color: Colors.white, fontSize: 22)),
          SizedBox(height: 20),
          Text(
            user != null ? "${user!.email}" : "No email available",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Icon(Icons.logout),
            onPressed: _logout,
            label: Text("Logout", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _tabs = [
      _buildHomeTab(),
      _buildMaintenanceTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Dr. Vehicle', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: 'Maintenance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
