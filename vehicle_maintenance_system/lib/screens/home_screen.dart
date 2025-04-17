import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'vehicle_form_screen.dart';
import 'vehicle_list_screen.dart';
import 'maintenance_form.dart';
import 'maintenance_info_screen.dart';
import 'service_schedule_page.dart';
import 'bluetooth_scan_page.dart';
import 'send_obd_command_page.dart';
import 'obd2_diagnosis_page.dart';
import 'info_screen.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

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
        final firstVehicle = firstDoc.data();
        firstVehicle['id'] = firstDoc.id;
        setState(() {
          selectedVehicle = firstVehicle;
        });
      }
    }
  }

  String _getVehicleImage(String? vehicleType) {
    switch (vehicleType?.toLowerCase()) {
      case 'car':
        return 'assets/logo/car.png';
      case 'bike':
        return 'assets/logo/Bike.png';
      case 'truck':
        return 'assets/logo/Truck.png';
      case 'bus':
        return 'assets/logo/Bus.png';
      case 'van':
        return 'assets/logo/Van.png';
      case 'suv':
        return 'assets/logo/Suv.png';
      default:
        return 'assets/logo/car.png';
    }
  }

  void _logout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDarkCard,
        title: Text("Confirm Logout", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to logout?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: TextStyle(color: kYellow))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Logout", style: TextStyle(color: kYellow))),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login_screen', (_) => false);
    }
  }

  Widget buildCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6)],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: kYellow),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            ),
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              _getVehicleImage(selectedVehicle?['vehicle_type']),
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          if (selectedVehicle != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "${selectedVehicle!['model']} (${selectedVehicle!['vehicle_number']})",
                style: TextStyle(color: kYellow, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                buildCard("Vehicles", Icons.directions_car, () async {
                  final vehicleData = await Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleListScreen()));
                  if (vehicleData != null) setState(() => selectedVehicle = vehicleData);
                }),
                buildCard("Vehicle Info", Icons.settings, () {
                  if (selectedVehicle != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleInfoScreen(vehicleData: selectedVehicle!)));
                  } else {
                    _showSnack("Please select a vehicle.");
                  }
                }),
                buildCard("Maintenance Info", Icons.build, () {
                  if (selectedVehicle != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceInfoScreen(vehicleData: selectedVehicle!)));
                  } else {
                    _showSnack("Please select a vehicle.");
                  }
                }),
                buildCard("Service Schedule", Icons.calendar_today, () {
                  if (selectedVehicle != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceSchedulePage(vehicleData: selectedVehicle!)));
                  } else {
                    _showSnack("Please select a vehicle.");
                  }
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
          buildCard("OBD-II Connect", Icons.bluetooth, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => BluetoothScanPage()));
          }),
          buildCard("OBD2 Data", Icons.car_repair, () {
            if (BluetoothScanPage.obdCharacteristic != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SendObdCommandPage(obdCharacteristic: BluetoothScanPage.obdCharacteristic!)));
            } else {
              _showSnack("Please connect to an OBD device first.");
            }
          }),
          buildCard("OBD2 Diagnosis", Icons.warning_amber_rounded, () {
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
          Icon(Icons.account_circle, size: 100, color: kYellow),
          SizedBox(height: 16),
          Text("User Profile", style: TextStyle(color: Colors.white, fontSize: 22)),
          SizedBox(height: 10),
          Text(user?.email ?? "No email available", style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kYellow,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Icon(Icons.logout),
            label: Text("Logout", style: TextStyle(fontSize: 16)),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.grey[800],
    ));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [
      _buildHomeTab(),
      _buildMaintenanceTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        title: Text('Dr.Vehicle', style: TextStyle(color: kYellow, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: tabs[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: kYellow,
              foregroundColor: Colors.black,
              child: Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleFormScreen()));
                await Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceFormScreen()));
              },
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kDarkCard,
        selectedItemColor: kYellow,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maintenance'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
