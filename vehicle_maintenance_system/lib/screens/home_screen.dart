import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'vehicle_form_screen.dart';
import 'vehicle_list_screen.dart';
import 'maintenance_form.dart';
import 'maintenance_info_screen.dart';
import 'service_schedule_page.dart';
import 'bluetooth_scan_page.dart';
import 'send_obd_command_page.dart';
import 'obd2_diagnosis_page.dart';
import 'info_screen.dart';
import 'report_screen.dart';

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
  String searchQuery = '';
  final int _notificationCount = 0; // Add notification count variable

  // Carousel variables
  final List<String> homeCarouselImages = [
    'assets/logo/Carousel1.png',
    'assets/logo/Carousel2.png',
    'assets/logo/Carousel3.png',
  ];
  int _currentHomeCarouselIndex = 0;

  final List<String> maintenanceCarouselImages = [
    'assets/logo/Carousel4.png',
    'assets/logo/Carousel5.png',
    'assets/logo/Carousel6.png',
  ];
  int _currentMaintenanceCarouselIndex = 0;

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
        setState(() => isFirstLogin = true);
      } else {
        final firstDoc = vehiclesSnapshot.docs.first;
        final firstVehicle = firstDoc.data();
        firstVehicle['id'] = firstDoc.id;
        setState(() => selectedVehicle = firstVehicle);
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
        title:
            const Text("Confirm Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to logout?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: kYellow)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: kYellow)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login_screen', (_) => false);
    }
  }

  Widget buildCard(String title, IconData icon, VoidCallback onTap) {
    // Special styling for Reports button only
    if (title == 'Reports') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GestureDetector(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkCard,
                foregroundColor: kYellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(icon, size: 24),
              label: Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: onTap,
            ),
          ),
        ),
      );
    }

    // Default styling for all other buttons
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: kYellow),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _allCards {
    return [
      // Home tab cards
      {
        'title': 'Vehicles',
        'icon': Icons.directions_car,
        'tab': 0,
        'onTap': () async {
          final vehicleData = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleListScreen()),
          );
          if (vehicleData != null) {
            setState(() => selectedVehicle = vehicleData);
          }
        },
      },
      {
        'title': 'Vehicle Info',
        'icon': Icons.settings,
        'tab': 0,
        'onTap': () {
          if (selectedVehicle != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    VehicleInfoScreen(vehicleData: selectedVehicle!),
              ),
            );
          } else {
            _showSnack("Please select a vehicle.");
          }
        },
      },
      {
        'title': 'Maintenance Info',
        'icon': Icons.build,
        'tab': 0,
        'onTap': () {
          if (selectedVehicle != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MaintenanceInfoScreen(vehicleData: selectedVehicle!),
              ),
            );
          } else {
            _showSnack("Please select a vehicle.");
          }
        },
      },
      {
        'title': 'Service Schedule',
        'icon': Icons.calendar_today,
        'tab': 0,
        'onTap': () {
          if (selectedVehicle != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ServiceSchedulePage(vehicleData: selectedVehicle!),
              ),
            );
          } else {
            _showSnack("Please select a vehicle.");
          }
        },
      },
      {
        'title': 'Reports',
        'icon': Icons.document_scanner,
        'tab': 0,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReportScreen(vehicleData: selectedVehicle!)),
          );
        },
      },
      // Maintenance tab cards
      {
        'title': 'OBD-II Connect',
        'icon': Icons.bluetooth,
        'tab': 1,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BluetoothScanPage()),
          );
        },
      },
      {
        'title': 'OBD2 Data',
        'icon': Icons.car_repair,
        'tab': 1,
        'onTap': () {
          if (BluetoothScanPage.obdCharacteristic != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SendObdCommandPage(
                  obdCharacteristic: BluetoothScanPage.obdCharacteristic!,
                ),
              ),
            );
          } else {
            _showSnack("Please connect to an OBD device first.");
          }
        },
      },
      {
        'title': 'OBD2 Diagnosis',
        'icon': Icons.warning_amber_rounded,
        'tab': 1,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Obd2DiagnosisPage()),
          );
        },
      },
      {
        'title': 'OBD-II Report',
        'icon': Icons.document_scanner,
        'tab': 1,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BluetoothScanPage()),
          );
        },
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredCards {
    return _allCards
        .where((card) => card['title']
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        title: const Text(
          'Dr.Vehicle',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: kYellow),
                onPressed: () {
                  _showSnack("Notifications feature coming soon!");
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildMaintenanceTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: kYellow,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
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
        backgroundColor: kDarkCard,
        selectedItemColor: kYellow,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.build), label: 'Maintenance'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: kDarkCard,
                hintText: 'Search...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: kYellow),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          if (selectedVehicle != null && searchQuery.isEmpty) ...[
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 8)
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                _getVehicleImage(selectedVehicle?['vehicle_type']),
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "${selectedVehicle!['model']} (${selectedVehicle!['vehicle_number']})",
                style: const TextStyle(
                  color: kYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // First row of regular grid items
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: _filteredCards
                      .where((card) =>
                          (searchQuery.isNotEmpty || card['tab'] == 0) &&
                          card['title'] != 'Reports')
                      .map((card) =>
                          buildCard(card['title'], card['icon'], card['onTap']))
                      .toList(),
                ),

      // Special Reports button below the grid
      // Update the special Reports button to match the onTap behavior from the grid
      if (_filteredCards.any((card) =>
          card['title'] == 'Reports' &&
          (searchQuery.isNotEmpty || card['tab'] == 0)))
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: buildCard(
            'Reports',
            Icons.document_scanner,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportScreen(vehicleData: selectedVehicle!)),
              );
            },
          ),
        ),
    ],
  ),
),
          if (searchQuery.isEmpty) ...[
            const Divider(color: Colors.grey, height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Featured Vehicles",
                style: TextStyle(
                  color: kYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CarouselSlider(
              items: homeCarouselImages.map((imagePath) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 8)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                height: 180,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                viewportFraction: 0.8,
                onPageChanged: (index, reason) {
                  setState(() => _currentHomeCarouselIndex = index);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: homeCarouselImages.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentHomeCarouselIndex == entry.key
                        ? kYellow
                        : Colors.grey.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            CarouselSlider(
              items: maintenanceCarouselImages.map((imagePath) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 8)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                height: 180,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                viewportFraction: 0.8,
                onPageChanged: (index, reason) {
                  setState(() => _currentMaintenanceCarouselIndex = index);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: maintenanceCarouselImages.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentMaintenanceCarouselIndex == entry.key
                        ? kYellow
                        : Colors.grey.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text(
                "Welcome to OBD2 Diagnostics",
                style: TextStyle(
                  color: kYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.grey, height: 1, thickness: 0.5),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _filteredCards
                  .where((card) => searchQuery.isNotEmpty || card['tab'] == 1)
                  .map((card) =>
                      buildCard(card['title'], card['icon'], card['onTap']))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: kYellow),
          const SizedBox(height: 16),
          const Text(
            "User Profile",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 10),
          Text(
            user?.email ?? "No email available",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kYellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.logout),
            label: const Text("Logout", style: TextStyle(fontSize: 16)),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}
