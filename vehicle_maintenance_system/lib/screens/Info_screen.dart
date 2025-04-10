import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InfoScreen extends StatefulWidget {
  final String vehicleId;

  const InfoScreen({super.key, required this.vehicleId});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  Map<String, dynamic>? vehicleData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVehicleData();
  }

  Future<void> fetchVehicleData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (doc.exists) {
        setState(() {
          vehicleData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle data not found')),
        );
      }
    } catch (e) {
      print('Error fetching vehicle data: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load vehicle data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Vehicle Info", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : vehicleData == null
              ? Center(
                  child: Text(
                    'No vehicle data available.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logo/car.png',
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 20),
                      buildInfoTile('Model', vehicleData!['model']),
                      buildInfoTile('Vehicle Number', vehicleData!['vehicle_number']),
                      buildInfoTile('Fuel Type', vehicleData!['fuel_type']),
                      buildInfoTile('Power', vehicleData!['power']),
                      buildInfoTile('Mileage', vehicleData!['mileage']),
                      buildInfoTile('First Registration', vehicleData!['registration_date']),
                    ],
                  ),
                ),
    );
  }

  Widget buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 16)),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
