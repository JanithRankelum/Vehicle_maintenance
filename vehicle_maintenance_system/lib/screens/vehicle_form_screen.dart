import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_vehicle/screens/maintenance_form.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

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

  Future<void> _saveVehicleData() async {
    if (_formKey.currentState!.validate()) {
      try {
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
          SnackBar(
            content: Text('Vehicle details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MaintenanceFormScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving vehicle: $e'),
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
          'VEHICLE INFORMATION',
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
                _buildTextField("Owner Name", _ownerNameController),
                const SizedBox(height: 16),
                _buildTextField("Vehicle Number", _vehicleNumberController),
                const SizedBox(height: 16),
                _buildTextField("Vehicle Company", _vehicleCompanyController),
                const SizedBox(height: 16),
                _buildDropdownField("Vehicle Type", _vehicleTypeController, vehicleTypes),
                const SizedBox(height: 16),
                _buildTextField("Model", _modelController),
                const SizedBox(height: 16),
                _buildTextField("Year", _yearController, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField("Registration Number", _registrationNumberController),
                const SizedBox(height: 16),
                _buildTextField("Engine Number", _engineNumberController),
                const SizedBox(height: 16),
                _buildTextField("Chassis Number", _chassisNumberController),
                const SizedBox(height: 16),
                _buildDropdownField("Fuel Type", _fuelTypeController, fuelTypes),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveVehicleData,
                  child: const Text(
                    'SAVE & CONTINUE',
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
      {int maxLines = 1, TextInputType? keyboardType}) {
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
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, List<String> options) {
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : null,
      dropdownColor: kDarkCard,
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
      onChanged: (String? newValue) {
        setState(() {
          controller.text = newValue!;
        });
      },
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(
            option,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      validator: (value) => value == null || value.isEmpty ? 'Please select $label' : null,
    );
  }
}