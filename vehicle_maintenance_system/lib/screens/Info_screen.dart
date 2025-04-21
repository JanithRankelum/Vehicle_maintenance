import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class VehicleInfoScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const VehicleInfoScreen({super.key, required this.vehicleData});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  late Map<String, dynamic> updatedData;
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    updatedData = Map<String, dynamic>.from(widget.vehicleData);
  }

  void _updateVehicleInfo() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(updatedData['vehicle_id'])
              .update({
            ...updatedData,
            'updated_at': FieldValue.serverTimestamp(),
          });

          setState(() => isEditing = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehicle updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating vehicle: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoTile(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            label,
            style: TextStyle(
              color: kYellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: isEditing
              ? TextFormField(
                  initialValue: updatedData[key]?.toString() ?? '',
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter $label",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => updatedData[key] = val,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter $label';
                    }
                    return null;
                  },
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    updatedData[key]?.toString() ?? 'Not specified',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Timestamp? timestamp = widget.vehicleData['updated_at'];
    String formattedTime = timestamp != null
        ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
        : 'Not available';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vehicle Details',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.save : Icons.edit,
              color: kYellow,
            ),
            onPressed: () {
              if (isEditing) {
                _updateVehicleInfo();
              } else {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
      ),
      backgroundColor: kBackground,
      body: Form(
        key: _formKey,
        child: Padding(
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
              Container(
                decoration: BoxDecoration(
                  color: kDarkCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    "Last Updated",
                    style: TextStyle(
                      color: kYellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _updateVehicleInfo,
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}