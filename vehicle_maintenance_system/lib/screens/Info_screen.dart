import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_vehicle/screens/vehicle_form_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
  }

  Future<DocumentSnapshot?> _fetchVehicleData() async {
    if (_userId == null) return null;
    return await FirebaseFirestore.instance.collection('vehicles').doc(_userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vehicle Info")),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _fetchVehicleData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
            return Center(child: Text("No vehicle data found"));
          }

          var vehicleData = snapshot.data!.data() as Map<String, dynamic>;

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

                  SizedBox(height: 20), // Increased spacing

                  // Vehicle Details Section
                  _buildSectionHeader(context, "Vehicle Details"),
                  _buildDetailRow(context, "Owner Name", vehicleData['owner_name']),
                  _buildDetailRow(context, "Vehicle Number", vehicleData['vehicle_number']),
                  _buildDetailRow(context, "Vehicle Company", vehicleData['vehicle_company']),
                  _buildDetailRow(context, "Model", vehicleData['model']),
                  _buildDetailRow(context, "Vehicle Type", vehicleData['vehicle_type']),
                  _buildDetailRow(context, "Year", vehicleData['year']),
                  _buildDetailRow(context, "Fuel Type", vehicleData['fuel_type']),
                  _buildDetailRow(context, "Registration Number", vehicleData['registration_number']),
                  _buildDetailRow(context, "Chassis Number", vehicleData['chassis_number']),
                  _buildDetailRow(context, "Engine Number", vehicleData['engine_number']),

                  SizedBox(height: 20), // Increased spacing

                  // Maintenance & Policy History Section
                  _buildSectionHeader(context, "Maintenance & Policy History"),
                  _buildDetailRow(context, "Insurance Company", vehicleData['insurance_company']),
                  _buildDetailRow(context, "Insurance Policy Number", vehicleData['insurance_policy_number']),
                  _buildDetailRow(context, "Insurance Expiry Date", vehicleData['insurance_expiry']),
                  _buildDetailRow(context, "Last Tire Replace", vehicleData['last_tire_replace']),
                  _buildDetailRow(context, "Last Oil Change", vehicleData['last_oil_change']),
                  _buildDetailRow(context, "Last Service Date", vehicleData['last_service']),
                  _buildDetailRow(context, "Other Maintenance", vehicleData['other_maintenance']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        Divider(), // Separator line
        SizedBox(height: 10),
      ],
    );
  }


  Widget _buildDetailRow(BuildContext context, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$title: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? "N/A", style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}