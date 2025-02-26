import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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

  Future<void> _updateMaintenanceHistory(String userId, ServiceSchedule schedule) async {
    await FirebaseFirestore.instance.collection('vehicles').doc(userId).update({
      'last_tire_replace': schedule.lastTireReplace,
      'last_oil_change': schedule.lastOilChange,
      'last_service': schedule.lastService,
      'insurance_expiry': schedule.insuranceExpiry,
      'insurance_company': schedule.insuranceCompany,
      'insurance_policy_number': schedule.insurancePolicyNumber,
      'other_maintenance': schedule.otherMaintenance,
    });
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
          List<dynamic> maintenanceHistory = vehicleData['maintenance_history'] ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Refresh the screen
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  SizedBox(height: 20),
                  _buildSectionHeader(context, "Vehicle Details"),
                  _buildDetailRow(context, "Owner Name", vehicleData['owner_name']),
                  _buildDetailRow(context, "Vehicle Number", vehicleData['vehicle_number']),
                  _buildDetailRow(context, "Vehicle Company", vehicleData['vehicle_company']),
                  _buildDetailRow(context, "Model", vehicleData['model']),
                  _buildDetailRow(context, "Year", vehicleData['year']),
                  _buildDetailRow(context, "Fuel Type", vehicleData['fuel_type']),
                  _buildDetailRow(context, "Chassis Number", vehicleData['chassis_number']),
                  _buildDetailRow(context, "Engine Number", vehicleData['engine_number']),

                  SizedBox(height: 20),
                  _buildSectionHeader(context, "Maintenance & Policy History"),
                  _buildDetailRow(context, "Insurance Company", vehicleData['insurance_company']),
                  _buildDetailRow(context, "Insurance Policy Number", vehicleData['insurance_policy_number']),
                  _buildDetailRow(context, "Insurance Expiry Date", vehicleData['insurance_expiry']),
                  _buildDetailRow(context, "Last Tire Replace", vehicleData['last_tire_replace']),
                  _buildDetailRow(context, "Last Oil Change", vehicleData['last_oil_change']),
                  _buildDetailRow(context, "Last Service Date", vehicleData['last_service']),
                  _buildDetailRow(context, "Other Maintenance", vehicleData['other_maintenance']),

                  SizedBox(height: 20),
                  if (maintenanceHistory.isNotEmpty)
                    _buildMaintenanceHistoryList(context, maintenanceHistory)
                  else
                    Center(child: Text("No maintenance records found.")),
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
        Divider(),
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

  Widget _buildMaintenanceHistoryList(BuildContext context, List<dynamic> maintenanceHistory) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Disable scrolling inside ListView
      itemCount: maintenanceHistory.length,
      itemBuilder: (context, index) {
        var entry = maintenanceHistory[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date: ${entry['date']}", style: TextStyle(fontWeight: FontWeight.bold)),
                if (entry['last_tire_replace'] != null)
                  _buildDetailRow(context, "Last Tire Replace", entry['last_tire_replace']),
                if (entry['last_oil_change'] != null)
                  _buildDetailRow(context, "Last Oil Change", entry['last_oil_change']),
                if (entry['last_service'] != null)
                  _buildDetailRow(context, "Last Service", entry['last_service']),
                if (entry['insurance_expiry'] != null)
                  _buildDetailRow(context, "Insurance Expiry", entry['insurance_expiry']),
                if (entry['insurance_company'] != null)
                  _buildDetailRow(context, "Insurance Company", entry['insurance_company']),
                if (entry['insurance_policy_number'] != null)
                  _buildDetailRow(context, "Insurance Policy Number", entry['insurance_policy_number']),
                if (entry['other_maintenance'] != null)
                  _buildDetailRow(context, "Other Maintenance", entry['other_maintenance']),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ServiceSchedule {
  final String lastTireReplace;
  final String lastOilChange;
  final String lastService;
  final String insuranceExpiry;
  final String insuranceCompany;
  final String insurancePolicyNumber;
  final String otherMaintenance;

  ServiceSchedule({
    required this.lastTireReplace,
    required this.lastOilChange,
    required this.lastService,
    required this.insuranceExpiry,
    required this.insuranceCompany,
    required this.insurancePolicyNumber,
    required this.otherMaintenance,
  });
}