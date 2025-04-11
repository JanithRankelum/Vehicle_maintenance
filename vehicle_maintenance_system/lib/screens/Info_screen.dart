import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VehicleInfoScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const VehicleInfoScreen({Key? key, required this.vehicleData})
      : super(key: key);

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  late Map<String, dynamic> updatedData;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    updatedData = Map<String, dynamic>.from(widget.vehicleData);
  }

  void _updateVehicleInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('user_id', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(docId)
            .update({
          ...updatedData,
          'updated_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle info updated successfully')),
        );
      }
    }
  }

  Widget _buildInfoTile(String label, String key) {
    final value = updatedData[key];
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
                onChanged: (val) => updatedData[key] = val,
              )
            : Text(
                value?.toString() ?? "N/A",
                style: TextStyle(color: Colors.white),
              ),
        tileColor: Colors.grey[850],
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Timestamp? timestamp = widget.vehicleData['updated_at'];
    String formattedTime = timestamp != null
        ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Info'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _updateVehicleInfo();
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
            _buildInfoTile("Model", "model"),
            _buildInfoTile("Vehicle Number", "vehicle_number"),
            _buildInfoTile("Vehicle Type", "vehicle_type"),
            _buildInfoTile("Company", "vehicle_company"),
            _buildInfoTile("Fuel Type", "fuel_type"),
            _buildInfoTile("Year", "year"),
            _buildInfoTile("Chassis Number", "chassis_number"),
            _buildInfoTile("Engine Number", "engine_number"),
            _buildInfoTile("Registration Number", "registration_number"),
            _buildInfoTile("Owner Name", "owner_name"),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                title: Text("Last Updated",
                    style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold)),
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
