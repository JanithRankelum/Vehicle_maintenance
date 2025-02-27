import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VehicleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicleData; // Accept existing vehicle data

  VehicleFormScreen({this.vehicleData});

  @override
  _VehicleFormScreenState createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _vehicleCompanyController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _chassisNumberController = TextEditingController();
  final TextEditingController _fuelTypeController = TextEditingController();
  final TextEditingController _insuranceCompanyController = TextEditingController();
  final TextEditingController _insurancePolicyNumberController = TextEditingController();
  final TextEditingController _insuranceExpiryController = TextEditingController();
  final TextEditingController _lastOilChangeController = TextEditingController();
  final TextEditingController _lastTireReplaceController = TextEditingController();
  final TextEditingController _lastServiceController = TextEditingController();
  final TextEditingController _otherMaintenanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  // Load existing vehicle data into controllers
  void _loadVehicleData() {
    if (widget.vehicleData != null) {
      _ownerNameController.text = widget.vehicleData!['owner_name'] ?? '';
      _vehicleNumberController.text = widget.vehicleData!['vehicle_number'] ?? '';
      _vehicleCompanyController.text = widget.vehicleData!['vehicle_company'] ?? '';
      _vehicleTypeController.text = widget.vehicleData!['vehicle_type'] ?? '';
      _modelController.text = widget.vehicleData!['model'] ?? '';
      _yearController.text = widget.vehicleData!['year'] ?? '';
      _registrationNumberController.text = widget.vehicleData!['registration_number'] ?? '';
      _engineNumberController.text = widget.vehicleData!['engine_number'] ?? '';
      _chassisNumberController.text = widget.vehicleData!['chassis_number'] ?? '';
      _fuelTypeController.text = widget.vehicleData!['fuel_type'] ?? '';
      _insuranceCompanyController.text = widget.vehicleData!['insurance_company'] ?? '';  
      _insurancePolicyNumberController.text = widget.vehicleData!['insurance_policy_number'] ?? '';
      _insuranceExpiryController.text = _formatDate(widget.vehicleData!['insurance_expiry']);
      _lastOilChangeController.text = _formatDate(widget.vehicleData!['last_oil_change']);
      _lastTireReplaceController.text = _formatDate(widget.vehicleData!['last_tire_replace']);
      _lastServiceController.text = _formatDate(widget.vehicleData!['last_service']);
      _otherMaintenanceController.text = widget.vehicleData!['other_maintenance'] ?? '';
    }
  }

  // Function to format date safely
  String _formatDate(dynamic date) {
    if (date == null || date.isEmpty) return '';
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  // Function to show Date Picker
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  // Save or update vehicle data
  void _saveVehicleData() async {
    if (_formKey.currentState!.validate()) {
      String userId = _auth.currentUser!.uid;

      await FirebaseFirestore.instance.collection('vehicles').doc(userId).set({
        'owner_name': _ownerNameController.text,
        'vehicle_number': _vehicleNumberController.text,
        'vehicle_company': _vehicleCompanyController.text,
        'vehicle_type': _vehicleTypeController.text,
        'model': _modelController.text,
        'year': _yearController.text,
        'registration_number': _registrationNumberController.text,
        'engine_number': _engineNumberController.text,
        'chassis_number': _chassisNumberController.text,
        'fuel_type': _fuelTypeController.text, 
        'insurance_company': _insuranceCompanyController.text,
        'insurance_policy_number': _insurancePolicyNumberController.text,
        'insurance_expiry': _insuranceExpiryController.text,
        'last_oil_change': _lastOilChangeController.text,
        'last_tire_replace': _lastTireReplaceController.text,
        'last_service': _lastServiceController.text,
        'other_maintenance': _otherMaintenanceController.text,
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle details updated successfully!')),
      );

      Navigator.pop(context); // Return to Home Screen
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
                _buildTextField("Owner Name", _ownerNameController),
                _buildTextField("Vehicle Number", _vehicleNumberController),
                _buildTextField("Vehicle Company", _vehicleCompanyController),
                _buildTextField("Vehicle Type", _vehicleTypeController),
                _buildTextField("Model", _modelController),
                _buildTextField("Year", _yearController, keyboardType: TextInputType.number),
                _buildTextField("Registration Number", _registrationNumberController),
                _buildTextField("Engine Number", _engineNumberController),
                _buildTextField("Chassis Number", _chassisNumberController),
                _buildTextField("Fuel Type", _fuelTypeController),
                _buildTextField("Insurance Company", _insuranceCompanyController),
                _buildTextField("Insurance Policy Number", _insurancePolicyNumberController),
                _buildDateField("Insurance Expiry", _insuranceExpiryController),
                _buildDateField("Last Oil Change", _lastOilChangeController),
                _buildDateField("Last Tire Replace", _lastTireReplaceController),
                _buildDateField("Last Service", _lastServiceController),
                _buildTextField("Other Maintenance", _otherMaintenanceController, maxLines: 3),
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

  // Common text field builder
  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  // Common date field builder
  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true, // Prevents keyboard from showing
      onTap: () => _selectDate(context, controller),
    );
  }
}