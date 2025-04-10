import 'package:dr_vehicle/screens/maintenance_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_vehicle/screens/vehicle_form_screen.dart';
import 'package:dr_vehicle/screens/bluetooth_scan_page.dart';
import 'package:dr_vehicle/screens/send_obd_command_page.dart';
import 'package:dr_vehicle/screens/obd2_diagnosis_page.dart';
import 'package:dr_vehicle/screens/service_schedule_page.dart';
import 'package:dr_vehicle/screens/vehicle_list_screen.dart';
import 'package:dr_vehicle/screens/maintenance_form.dart';
import 'package:dr_vehicle/screens/info_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  Map<String, dynamic>? selectedVehicle;
  bool isFirstLogin = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _checkIfFirstLogin();
  }

  Future<void> _checkIfFirstLogin() async {
    if (user != null) {
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('user_id', isEqualTo: user!.uid)
          .get();

      if (vehiclesSnapshot.docs.isEmpty) {
        setState(() {
          isFirstLogin = true;
        });
      } else {
        final firstDoc = vehiclesSnapshot.docs.first;
        final firstVehicle = firstDoc.data() as Map<String, dynamic>;
        firstVehicle['id'] = firstDoc.id; // ✅ Attach document ID
        setState(() {
          selectedVehicle = firstVehicle;
        });
      }
    }
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
          if (selectedVehicle != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "${selectedVehicle!['model']} (${selectedVehicle!['vehicle_number']})",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                buildCard("Vehicles", Icons.directions_car_filled, Colors.teal.shade700, () async {
                  final vehicleData = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VehicleListScreen()),
                  );
                  if (vehicleData != null) {
                    setState(() {
                      selectedVehicle = vehicleData;
                    });
                  }
                }),
                buildCard("Vehicle Info", Icons.info_outline, Colors.blueAccent.shade700, () {
                  if (selectedVehicle != null && selectedVehicle!['id'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InfoScreen(vehicleId: selectedVehicle!['id']),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Vehicle ID is missing.")),
                    );
                  }
                }),
                buildCard("Maintenance Info", Icons.directions_car_filled, const Color.fromARGB(255, 121, 0, 0), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceInfoScreen()));
                }),
                buildCard("Service Schedule", Icons.build_circle_outlined, Colors.deepPurple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceSchedulePage(vehicleData: selectedVehicle!)));
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.greenAccent,
              child: Icon(Icons.add, color: Colors.black),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VehicleFormScreen()),
                );
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MaintenanceFormScreen()),
                );
              },
            )
          : null,
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
