import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dr_vehicle/screens/vehicle_form_screen.dart'; // Import your VehicleFormScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _userId;

  // Controllers for updating maintenance records
  final TextEditingController _otherMaintenanceController = TextEditingController();
  DateTime? _brakeOilChangeDate;
  DateTime? _tireReplaceDate;
  DateTime? _serviceDate;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser!.uid;
  }

  // Fetch vehicle data
  Future<DocumentSnapshot> _fetchVehicleData() async {
    return await FirebaseFirestore.instance.collection('vehicles').doc(_userId).get();
  }

  // Function to add a new maintenance record
  void _updateMaintenance() async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FirebaseFirestore.instance.collection('vehicles').doc(_userId).update({
      'maintenance_history': FieldValue.arrayUnion([
        {
          'last_brake_oil_change': _brakeOilChangeDate != null ? DateFormat('yyyy-MM-dd').format(_brakeOilChangeDate!) : null,
          'last_tire_replace': _tireReplaceDate != null ? DateFormat('yyyy-MM-dd').format(_tireReplaceDate!) : null,
          'last_service': _serviceDate != null ? DateFormat('yyyy-MM-dd').format(_serviceDate!) : null,
          'other_maintenance': _otherMaintenanceController.text.isNotEmpty ? _otherMaintenanceController.text : null,
          'date': date,
        }
      ])
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maintenance record updated!')));
    setState(() {
      _brakeOilChangeDate = null;
      _tireReplaceDate = null;
      _serviceDate = null;
      _otherMaintenanceController.clear();
    });
  }

  // Function to pick a date
  Future<void> _selectDate(BuildContext context, Function(DateTime) setDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => setDate(picked));
    }
  }

  // Function to format date
  String formatDate(String date) {
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      return DateFormat('d MMMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  // Function for logout
  void _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login_screen', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Call logout function
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchVehicleData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error fetching data"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("No vehicle data found"));
          }

          var vehicleData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> maintenanceHistory = vehicleData['maintenance_history'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VehicleFormScreen(vehicleData: vehicleData)),
                        );
                      },
                      child: Text("Edit"),
                    ),
                  ),
                  Text(
                    "Vehicle Details",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 10),
                  _buildDetailRow("Owner Name", vehicleData['owner_name']),
                  _buildDetailRow("Vehicle Number", vehicleData['vehicle_number']),
                  _buildDetailRow("Vehicle Company", vehicleData['vehicle_company']),
                  _buildDetailRow("Model", vehicleData['model']),
                  _buildDetailRow("Year", vehicleData['year']),
                  _buildDetailRow("Last Brake Oil Change", formatDate(vehicleData['last_brake_oil_change'])),
                  _buildDetailRow("Last Tire Replace", formatDate(vehicleData['last_tire_replace'])),
                  _buildDetailRow("Last Service", formatDate(vehicleData['last_service'])),
                  _buildDetailRow("Other Maintenance", vehicleData['other_maintenance']),
                  SizedBox(height: 20),
                  Divider(),
                  Text(
                    "Maintenance History",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 10),
                  if (maintenanceHistory.isNotEmpty)
                    Column(
                      children: maintenanceHistory.map((entry) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Date: ${formatDate(entry['date'])}", style: TextStyle(fontWeight: FontWeight.bold)),
                                if (entry['last_brake_oil_change'] != null) _buildDetailRow("Last Brake Oil Change", entry['last_brake_oil_change']),
                                if (entry['last_tire_replace'] != null) _buildDetailRow("Last Tire Replace", entry['last_tire_replace']),
                                if (entry['last_service'] != null) _buildDetailRow("Last Service", entry['last_service']),
                                if (entry['other_maintenance'] != null) _buildDetailRow("Other Maintenance", entry['other_maintenance']),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Text("No maintenance records found."),
                  SizedBox(height: 20),
                  Divider(),
                  Text("Update Maintenance", style: Theme.of(context).textTheme.titleLarge),
                  _buildDateField("Last Brake Oil Change", _brakeOilChangeDate, (date) => _brakeOilChangeDate = date),
                  _buildDateField("Last Tire Replace", _tireReplaceDate, (date) => _tireReplaceDate = date),
                  _buildDateField("Last Service", _serviceDate, (date) => _serviceDate = date),
                  TextField(
                    controller: _otherMaintenanceController,
                    decoration: InputDecoration(labelText: "Other Maintenance"),
                    maxLines: 2,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _updateMaintenance,
                    child: Text("Update"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$title: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildDateField(String title, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return ListTile(
      title: Text(title),
      subtitle: Text(selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate) : "Select Date"),
      trailing: Icon(Icons.calendar_today),
      onTap: () => _selectDate(context, onDateSelected),
    );
  }
}
