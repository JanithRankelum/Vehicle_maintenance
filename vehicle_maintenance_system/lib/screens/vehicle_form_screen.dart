import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';  // For formatting the date

class VehicleFormScreen extends StatefulWidget {
  @override
  _VehicleFormScreenState createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _vehicleCompanyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _lastBrakeOilChangeController = TextEditingController();
  final TextEditingController _lastTireReplaceController = TextEditingController();
  final TextEditingController _lastServiceController = TextEditingController();
  final TextEditingController _otherMaintenanceController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to show Date Picker
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(1900); // Earliest date
    DateTime lastDate = DateTime.now(); // Latest date

    // Show date picker dialog
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    // If a date is picked, update the controller
    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate); // Format the date
      });
    }
  }

  void _saveVehicleData() async {
    if (_formKey.currentState!.validate()) {
      String userId = _auth.currentUser!.uid;

      await FirebaseFirestore.instance.collection('vehicles').doc(userId).set({
        'owner_name': _ownerNameController.text,
        'vehicle_number': _vehicleNumberController.text,
        'vehicle_company': _vehicleCompanyController.text,
        'model': _modelController.text,
        'year': _yearController.text,
        'last_brake_oil_change': _lastBrakeOilChangeController.text,
        'last_tire_replace': _lastTireReplaceController.text,
        'last_service': _lastServiceController.text,
        'other_maintenance': _otherMaintenanceController.text,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle details saved successfully!')),
      );

      // Navigate to Home Screen after saving details
      Navigator.pushReplacementNamed(context, '/home_screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vehicle Information")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _ownerNameController,
                  decoration: InputDecoration(labelText: "Owner Name"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: InputDecoration(labelText: "Vehicle Number"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: _vehicleCompanyController,
                  decoration: InputDecoration(labelText: "Vehicle Company"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(labelText: "Model"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(labelText: "Year"),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: _lastBrakeOilChangeController,
                  decoration: InputDecoration(labelText: "Last Brake-Oil Change Date"),
                  keyboardType: TextInputType.datetime,
                  validator: (value) => value!.isEmpty ? "Required" : null,
                  onTap: () {
                    _selectDate(context, _lastBrakeOilChangeController); // Show Date Picker
                  },
                ),
                TextFormField(
                  controller: _lastTireReplaceController,
                  decoration: InputDecoration(labelText: "Last Tire Replace Date"),
                  keyboardType: TextInputType.datetime,
                  validator: (value) => value!.isEmpty ? "Required" : null,
                  onTap: () {
                    _selectDate(context, _lastTireReplaceController); // Show Date Picker
                  },
                ),
                TextFormField(
                  controller: _lastServiceController,
                  decoration: InputDecoration(labelText: "Last Service Date"),
                  keyboardType: TextInputType.datetime,
                  validator: (value) => value!.isEmpty ? "Required" : null,
                  onTap: () {
                    _selectDate(context, _lastServiceController); // Show Date Picker
                  },
                ),
                TextFormField(
                  controller: _otherMaintenanceController,
                  decoration: InputDecoration(labelText: "Other Maintenance"),
                  maxLines: 3,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveVehicleData,
                  child: Text("Save & Continue"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

