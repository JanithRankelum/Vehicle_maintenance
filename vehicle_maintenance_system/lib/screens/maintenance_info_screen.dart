import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MaintenanceInfoScreen extends StatefulWidget {
  final String userId;
  final String vehicleId;

  const MaintenanceInfoScreen({
    Key? key,
    required this.userId,
    required this.vehicleId,
  }) : super(key: key);

  @override
  State<MaintenanceInfoScreen> createState() => _MaintenanceInfoScreenState();
}

class _MaintenanceInfoScreenState extends State<MaintenanceInfoScreen> {
  Map<String, dynamic> maintenanceData = {};
  bool isEditing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMaintenanceData();
  }

  Future<void> fetchMaintenanceData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('maintenance')
        .where('user_id', isEqualTo: widget.userId)
        .where('vehicle_id', isEqualTo: widget.vehicleId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        maintenanceData = snapshot.docs.first.data();
        maintenanceData['docId'] = snapshot.docs.first.id;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateMaintenanceData() async {
    if (maintenanceData['docId'] == null) return;

    await FirebaseFirestore.instance
        .collection('maintenance')
        .doc(maintenanceData['docId'])
        .update({
      'insurance_company': maintenanceData['insurance_company'],
      'insurance_policy_number': maintenanceData['insurance_policy_number'],
      'last_oil_change': maintenanceData['last_oil_change'],
      'last_service': maintenanceData['last_service'],
      'last_tire_replace': maintenanceData['last_tire_replace'],
      'other_maintenance': maintenanceData['other_maintenance'],
      'updated_at': FieldValue.serverTimestamp(),
    });

    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Maintenance info updated successfully")),
    );
  }

  Widget _buildInfoTile(String label, String key) {
    final value = maintenanceData[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: isEditing
            ? TextFormField(
                initialValue: value?.toString() ?? '',
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter $label",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                onChanged: (val) => maintenanceData[key] = val,
              )
            : Text(
                value?.toString() ?? "N/A",
                style: TextStyle(color: Colors.white),
              ),
        tileColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance Info'),
        backgroundColor: Colors.black,
        actions: [
          if (!isLoading && maintenanceData.isNotEmpty)
            IconButton(
              icon: Icon(isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (isEditing) {
                  updateMaintenanceData();
                } else {
                  setState(() {
                    isEditing = true;
                  });
                }
              },
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : maintenanceData.isEmpty
              ? Center(
                  child: Text(
                    "No maintenance record found.",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _buildInfoTile("Insurance Company", 'insurance_company'),
                      _buildInfoTile(
                          "Insurance Policy Number", 'insurance_policy_number'),
                      _buildInfoTile("Last Oil Change", 'last_oil_change'),
                      _buildInfoTile("Last Service", 'last_service'),
                      _buildInfoTile(
                          "Last Tire Replacement", 'last_tire_replace'),
                      _buildInfoTile(
                          "Other Maintenance", 'other_maintenance'),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: ListTile(
                          title: Text("Last Updated",
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            maintenanceData['updated_at'] != null
                                ? DateFormat.yMMMd().add_jm().format(
                                    maintenanceData['updated_at'].toDate())
                                : 'N/A',
                            style: TextStyle(color: Colors.white),
                          ),
                          tileColor: Colors.grey[850],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
