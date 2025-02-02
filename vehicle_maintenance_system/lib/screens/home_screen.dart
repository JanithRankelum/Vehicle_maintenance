import 'package:flutter/material.dart';
import 'package:dr_vehicle/services/vehicle_service.dart';
import 'package:dr_vehicle/models/vehicle_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VehicleService _vehicleService = VehicleService();
  Vehicle? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  void _loadVehicle() async {
    final vehicle = await _vehicleService.getUserVehicle();
    setState(() {
      _vehicle = vehicle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: _vehicle == null
          ? Center(child: Text("No vehicle found. Please add one."))
          : Column(
              children: [
                Text("Vehicle: ${_vehicle!.make} ${_vehicle!.model} (${_vehicle!.year})"),
                Text("Mileage: ${_vehicle!.mileage} km"),
                Text("Next Oil Change: ${_vehicle!.oilChangeDue} km"),
                Text("Next Tire Rotation: ${_vehicle!.tireRotationDue} km"),
              ],
            ),
    );
  }
}
