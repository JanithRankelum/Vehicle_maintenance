import 'package:flutter/material.dart';
import 'package:dr_vehicle/models/obd_model.dart'; // Make sure this import is correct
import 'package:dr_vehicle/services/service_schedule.dart';
import 'package:dr_vehicle/services/firestore_service.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class MaintenancePage extends StatefulWidget {
  final String vehicleId;
  final String make;
  final String model;
  final int year;
  final DateTime lastServiceDate; // Store as DateTime
  final DateTime insuranceExpire; // Store as DateTime

  MaintenancePage({
    required this.vehicleId,
    required this.make,
    required this.model,
    required this.year,
    required this.lastServiceDate,
    required this.insuranceExpire,
  });

  @override
  _MaintenancePageState createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  int mileage = 0;
  String nextService = "";
  String nextOilChange = "";
  String tireReplacement = "";
  String insuranceExpiry = "";
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    int obdMileage = await OBDService().fetchOBDMileage();

    if (obdMileage == -1) {
      obdMileage = 0; // Or a reasonable default, NOT 15000 if you want to force OBD
      // Show a message to the user that OBD data could not be retrieved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not retrieve mileage from OBD-II device.')),
      );
    }

    setState(() {
      mileage = obdMileage;
      nextService = ServiceScheduler.calculateNextService(
          mileage, widget.lastServiceDate.toIso8601String());
      nextOilChange =
          ServiceScheduler.calculateOilChange(mileage, widget.lastServiceDate.toIso8601String());
      tireReplacement = ServiceScheduler.calculateTireReplacement(mileage);
      insuranceExpiry =
          ServiceScheduler.calculateInsuranceExpiry(widget.insuranceExpire.toIso8601String());
    });

    await FirestoreService().saveVehicleData(widget.vehicleId, {
      "make": widget.make,
      "model": widget.model,
      "year": widget.year,
      "mileage": mileage,
      "lastServiceDate": widget.lastServiceDate.toIso8601String(), // Store as ISO 8601 string
      "nextServiceDate": nextService,
      "nextOilChange": nextOilChange,
      "nextTireReplace": tireReplacement,
      "insuranceExpire": widget.insuranceExpire.toIso8601String(), // Store as ISO 8601 string
    });

    setState(() {
      _isLoading = false; // Data loaded
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vehicle Maintenance")),
      body: _isLoading // Show loading indicator while data is loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildRow("Mileage", "$mileage km"),
                  _buildRow("Next Service", nextService),
                  _buildRow("Next Oil Change", nextOilChange),
                  _buildRow("Tire Replacement", tireReplacement),
                  _buildRow("Insurance Expiry", insuranceExpiry),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items to edges
        children: [
          Text("$label:", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value), // No need for expanded if using mainAxisAlignment
        ],
      ),
    );
  }
}