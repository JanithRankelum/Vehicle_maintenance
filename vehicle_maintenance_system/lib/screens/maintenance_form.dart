import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dr_vehicle/screens/home_screen.dart'; // Adjust path as needed

class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({super.key});

  @override
  _MaintenanceFormScreenState createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _insuranceCompanyController = TextEditingController();
  final TextEditingController _insurancePolicyController = TextEditingController();
  final TextEditingController _lastOilChangeController = TextEditingController();
  final TextEditingController _lastTireReplaceController = TextEditingController();
  final TextEditingController _lastServiceController = TextEditingController();
  final TextEditingController _otherMaintenanceController = TextEditingController();

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _saveMaintenanceData() async {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user == null) return;

      String userId = user.uid;

      // Fetch vehicles data for the authenticated user
      QuerySnapshot vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('user_id', isEqualTo: userId)
          .get();

      if (vehiclesSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No vehicles found for this user")),
        );
        return;
      }

      // Assuming that there is only one vehicle for the user in this case
      String vehicleId = vehiclesSnapshot.docs.first.id;

      // Ensure that the maintenance document is created with the `vehicle_id` field
      await FirebaseFirestore.instance
          .collection('maintenance')
          .doc(vehicleId) // Store maintenance data under vehicleId
          .set({
        'user_id': userId, // Ensure the user_id is stored for security validation
        'vehicle_id': vehicleId, // Add the vehicle_id field
        'insurance_company': _insuranceCompanyController.text,
        'insurance_policy_number': _insurancePolicyController.text,
        'last_oil_change': _lastOilChangeController.text,
        'last_tire_replace': _lastTireReplaceController.text,
        'last_service': _lastServiceController.text,
        'other_maintenance': _otherMaintenanceController.text,
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Maintenance info saved successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Maintenance Info")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField("Insurance Company", _insuranceCompanyController),
                _buildTextField("Insurance Policy Number", _insurancePolicyController),
                _buildDateField("Last Oil Change", _lastOilChangeController),
                _buildDateField("Last Tire Replace", _lastTireReplaceController),
                _buildDateField("Last Service", _lastServiceController),
                _buildTextField("Other Maintenance", _otherMaintenanceController, maxLines: 3),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveMaintenanceData,
                  child: Text("Save & Finish"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () => _selectDate(context, controller),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }
}
