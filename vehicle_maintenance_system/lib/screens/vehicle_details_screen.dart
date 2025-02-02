import 'package:flutter/material.dart';
import 'package:dr_vehicle/services/vehicle_service.dart';
import 'package:dr_vehicle/models/vehicle_model.dart';
import 'package:dr_vehicle/screens/home_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  @override
  _VehicleDetailsScreenState createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final VehicleService _vehicleService = VehicleService();

  void _saveVehicle() async {
    if (_makeController.text.isEmpty ||
        _modelController.text.isEmpty ||
        _yearController.text.isEmpty ||
        _mileageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All fields are required!")));
      return;
    }

    final int mileage = int.parse(_mileageController.text);
    final int year = int.parse(_yearController.text);

    final vehicle = Vehicle(
      id: '',
      make: _makeController.text,
      model: _modelController.text,
      year: year,
      mileage: mileage,
      oilChangeDue: mileage + 5000, // Example: Oil change every 5000 km
      tireRotationDue: mileage + 10000, // Example: Tire rotation every 10000 km
    );

    await _vehicleService.addVehicle(vehicle);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Vehicle")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _makeController, decoration: InputDecoration(labelText: "Make")),
            TextField(controller: _modelController, decoration: InputDecoration(labelText: "Model")),
            TextField(controller: _yearController, decoration: InputDecoration(labelText: "Year"), keyboardType: TextInputType.number),
            TextField(controller: _mileageController, decoration: InputDecoration(labelText: "Current Mileage"), keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveVehicle, child: Text("Save Vehicle")),
          ],
        ),
      ),
    );
  }
}
