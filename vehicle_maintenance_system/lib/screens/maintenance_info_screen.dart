import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MaintenanceInfoScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const MaintenanceInfoScreen({super.key, required this.vehicleData});

  @override
  State<MaintenanceInfoScreen> createState() => _MaintenanceInfoScreenState();
}

class _MaintenanceInfoScreenState extends State<MaintenanceInfoScreen> {
  Map<String, dynamic>? updatedData;
  bool isEditing = false;
  bool isLoading = true;
  String? docId;

  @override
  void initState() {
    super.initState();
    fetchMaintenanceData();
  }

  Future<void> fetchMaintenanceData() async {
    final user = FirebaseAuth.instance.currentUser;
    final vehicleId =
        widget.vehicleData['vehicle_id'] ?? widget.vehicleData['id'];

    if (user != null && vehicleId != null) {
      final query = await FirebaseFirestore.instance
          .collection('maintenance')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: vehicleId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        setState(() {
          docId = doc.id;
          updatedData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          updatedData = {
            'insurance_company': '',
            'insurance_policy_number': '',
            'last_oil_change': '',
            'last_service': '',
            'last_tire_replace': '',
            'other_maintenance': '',
            'updated_at': null,
          };
          isLoading = false;
        });
      }
    }
  }

  void _updateMaintenanceInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final vehicleId =
        widget.vehicleData['vehicle_id'] ?? widget.vehicleData['id'];

    if (user != null && updatedData != null) {
      final maintenanceCollection =
          FirebaseFirestore.instance.collection('maintenance');
      final dataToUpdate = {
        ...updatedData!,
        'updated_at': FieldValue.serverTimestamp(),
        'user_id': user.uid,
        'vehicle_id': vehicleId,
      };

      if (docId != null) {
        await maintenanceCollection.doc(docId).update(dataToUpdate);
      } else {
        final docRef = await maintenanceCollection.add(dataToUpdate);
        docId = docRef.id;
      }

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maintenance info updated successfully')),
      );
    }
  }

  Widget _buildInfoTile(String label, String key) {
    final value = updatedData?[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        title: Text(label,
            style: TextStyle(
                color: Colors.grey[400], fontWeight: FontWeight.bold)),
        subtitle: isEditing
            ? TextFormField(
                initialValue: value?.toString() ?? '',
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter $label",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                onChanged: (val) => updatedData![key] = val,
              )
            : Text(
                value?.toString() ?? "N/A",
                style: TextStyle(color: Colors.white),
              ),
        tileColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || updatedData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Maintenance Info'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Timestamp? timestamp = updatedData!['updated_at'];
    String formattedTime = timestamp != null
        ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance Info'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _updateMaintenanceInfo();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildInfoTile("Insurance Company", "insurance_company"),
            _buildInfoTile(
                "Insurance Policy Number", "insurance_policy_number"),
            _buildInfoTile("Last Oil Change", "last_oil_change"),
            _buildInfoTile("Last Service", "last_service"),
            _buildInfoTile("Last Tire Replacement", "last_tire_replace"),
            _buildInfoTile("Other Maintenance", "other_maintenance"),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                title: Text("Last Updated",
                    style: TextStyle(
                        color: Colors.grey[400], fontWeight: FontWeight.bold)),
                subtitle:
                    Text(formattedTime, style: TextStyle(color: Colors.white)),
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
