import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dr_vehicle/screens/home_screen.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kYellow,
              onPrimary: Colors.black,
              surface: kDarkCard,
              onSurface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: kBackground),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _saveMaintenanceData() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser;
        if (user == null) return;

        String userId = user.uid;

        QuerySnapshot vehiclesSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .where('user_id', isEqualTo: userId)
            .get();

        if (vehiclesSnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No vehicles found for this user"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        String vehicleId = vehiclesSnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('maintenance')
            .doc(vehicleId)
            .set({
          'user_id': userId,
          'vehicle_id': vehicleId,
          'insurance_company': _insuranceCompanyController.text,
          'insurance_policy_number': _insurancePolicyController.text,
          'last_oil_change': _lastOilChangeController.text,
          'last_tire_replace': _lastTireReplaceController.text,
          'last_service': _lastServiceController.text,
          'other_maintenance': _otherMaintenanceController.text,
          'updated_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Maintenance info saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving maintenance data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'MAINTENANCE INFORMATION',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField("Insurance Company", _insuranceCompanyController),
                const SizedBox(height: 16),
                _buildTextField("Insurance Policy Number", _insurancePolicyController),
                const SizedBox(height: 16),
                _buildDateField("Last Oil Change", _lastOilChangeController),
                const SizedBox(height: 16),
                _buildDateField("Last Tire Replacement", _lastTireReplaceController),
                const SizedBox(height: 16),
                _buildDateField("Last Service", _lastServiceController),
                const SizedBox(height: 16),
                _buildTextField("Other Maintenance", _otherMaintenanceController, maxLines: 3),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveMaintenanceData,
                  child: const Text(
                    'SAVE & FINISH',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kYellow),
        filled: true,
        fillColor: kDarkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kYellow),
        ),
      ),
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kYellow),
        filled: true,
        fillColor: kDarkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kYellow),
        ),
        suffixIcon: Icon(Icons.calendar_today, color: kYellow),
      ),
      onTap: () => _selectDate(context, controller),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }
}