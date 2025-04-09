import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_vehicle/screens/maintenance_form.dart'; // Make sure this path is correct

class VehicleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicleData;

  const VehicleFormScreen({super.key, this.vehicleData});

  @override
  _VehicleFormScreenState createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  final List<String> vehicleTypes = ['Car', 'Bike', 'Truck', 'Bus', 'Van', 'SUV'];
  final List<String> fuelTypes = ['Petrol', 'Diesel', 'Electric', 'Hybrid', 'CNG'];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

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
    }
  }

  void _saveVehicleData() async {
    if (_formKey.currentState!.validate()) {
      String userId = _auth.currentUser!.uid;

      await FirebaseFirestore.instance.collection('vehicles').add({
        'user_id': userId,
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
        'updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle details saved successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MaintenanceFormScreen()),
      );
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
                _buildDropdownField("Vehicle Type", _vehicleTypeController, vehicleTypes),
                _buildTextField("Model", _modelController),
                _buildTextField("Year", _yearController, keyboardType: TextInputType.number),
                _buildTextField("Registration Number", _registrationNumberController),
                _buildTextField("Engine Number", _engineNumberController),
                _buildTextField("Chassis Number", _chassisNumberController),
                _buildDropdownField("Fuel Type", _fuelTypeController, fuelTypes),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, List<String> options) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: controller.text.isNotEmpty ? controller.text : null,
      onChanged: (String? newValue) {
        setState(() {
          controller.text = newValue!;
        });
      },
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      validator: (value) => value == null || value.isEmpty ? 'Please select $label' : null,
    );
  }
}
