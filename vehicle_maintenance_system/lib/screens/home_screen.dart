import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _userId;

  // Fetch vehicle data from Firestore
  Future<DocumentSnapshot> _fetchVehicleData() async {
    _userId = _auth.currentUser!.uid;
    return await FirebaseFirestore.instance.collection('vehicles').doc(_userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login_screen');
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchVehicleData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error fetching data"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("No vehicle data found"));
          }

          var vehicleData = snapshot.data!.data() as Map<String, dynamic>;

          // Format the dates
          String formatDate(String date) {
            try {
              DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(date);
              return DateFormat('d MMMM yyyy').format(parsedDate); // Example: 8 February 2024
            } catch (e) {
              return date; // In case date is in wrong format
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Vehicle Details",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 20),
                _buildDetailRow("Owner Name", vehicleData['owner_name']),
                _buildDetailRow("Vehicle Number", vehicleData['vehicle_number']),
                _buildDetailRow("Vehicle Company", vehicleData['vehicle_company']),
                _buildDetailRow("Model", vehicleData['model']),
                _buildDetailRow("Year", vehicleData['year']),
                _buildDetailRow("Last Brake Oil Change", formatDate(vehicleData['last_brake_oil_change'])),
                _buildDetailRow("Last Tire Replace", formatDate(vehicleData['last_tire_replace'])),
                _buildDetailRow("Last Service", formatDate(vehicleData['last_service'])),
                _buildDetailRow("Other Maintenance", vehicleData['other_maintenance']),
                SizedBox(height: 20),
                Text(
                  "Created At: ${DateFormat('d MMMM yyyy h:mm a').format(vehicleData['created_at'].toDate())}",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
