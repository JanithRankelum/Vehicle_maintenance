import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dr_vehicle/screens/vehicle_form_screen.dart';

class InfoScreen extends StatefulWidget {
  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser!.uid;
  }

  // Fetch vehicle data from Firestore
  Future<DocumentSnapshot> _fetchVehicleData() async {
    return await FirebaseFirestore.instance.collection('vehicles').doc(_userId).get();
  }

  // Format date to a more readable format
  String formatDate(String date) {
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      return DateFormat('d MMMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vehicle Info & Maintenance"),
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
          List<dynamic> maintenanceHistory = vehicleData['maintenance_history'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edit Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleFormScreen(vehicleData: vehicleData),
                          ),
                        );
                      },
                      child: Text("Edit"),
                    ),
                  ),

                  // Vehicle Details Section
                  Text("Vehicle Details", style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 10),
                  _buildDetailRow("Owner Name", vehicleData['owner_name']),
                  _buildDetailRow("Vehicle Number", vehicleData['vehicle_number']),
                  _buildDetailRow("Vehicle Company", vehicleData['vehicle_company']),
                  _buildDetailRow("Vehicle Type", vehicleData['vehicle_type']),
                  _buildDetailRow("Model", vehicleData['model']),
                  _buildDetailRow("Year", vehicleData['year']),
                  _buildDetailRow("Registration Number", vehicleData['registration_number']),
                  _buildDetailRow("Engine Number", vehicleData['engine_number']),
                  _buildDetailRow("Chassis Number", vehicleData['chassis_number']),
                  _buildDetailRow("Fuel Type", vehicleData['fuel_type']),
                  _buildDetailRow("Insurance Company", vehicleData['insurance_company']),
                  _buildDetailRow("Insurance Policy Number", vehicleData['insurance_policy_number']),
                  _buildDetailRow("Insurance Expiry", formatDate(vehicleData['insurance_expiry'])),
                  _buildDetailRow("Last Brake Oil Change", formatDate(vehicleData['last_brake_oil_change'])),
                  _buildDetailRow("Last Tire Replace", formatDate(vehicleData['last_tire_replace'])),
                  _buildDetailRow("Last Service", formatDate(vehicleData['last_service'])),
                  _buildDetailRow("Other Maintenance", vehicleData['other_maintenance']),
                  SizedBox(height: 20),
                  Divider(),

                  // Maintenance History Section
                  Text("Maintenance History", style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 10),
                  if (maintenanceHistory.isNotEmpty)
                    Column(
                      children: maintenanceHistory.map((entry) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Date: ${formatDate(entry['date'])}", style: TextStyle(fontWeight: FontWeight.bold)),
                                if (entry['last_brake_oil_change'] != null) _buildDetailRow("Last Brake Oil Change", formatDate(entry['last_brake_oil_change'])),
                                if (entry['last_tire_replace'] != null) _buildDetailRow("Last Tire Replace", formatDate(entry['last_tire_replace'])),
                                if (entry['last_service'] != null) _buildDetailRow("Last Service", formatDate(entry['last_service'])),
                                if (entry['other_maintenance'] != null) _buildDetailRow("Other Maintenance", entry['other_maintenance']),
                                if (entry['further_maintenance'] != null) _buildDetailRow("Further Maintenance", entry['further_maintenance']),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Text("No maintenance records found."),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build a detail row
  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$title: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "N/A", style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}