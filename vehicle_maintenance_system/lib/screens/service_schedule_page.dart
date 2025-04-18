import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dr_vehicle/screens/noti_service.dart'; // Adjust path as needed

class ServiceSchedulePage extends StatefulWidget {
  final Map<String, dynamic>? vehicleData;

  const ServiceSchedulePage({Key? key, this.vehicleData}) : super(key: key);

  @override
  State<ServiceSchedulePage> createState() => _ServiceSchedulePageState();
}

class _ServiceSchedulePageState extends State<ServiceSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, DateTime?> _dates = {
    'insurance_expiry_date': null,
    'next_oil_change': null,
    'next_tire_replace': null,
    'next_service': null,
  };

  bool isSaving = false;
  String? currentVehicleId;
  String? currentMaintenanceId;

  @override
  void initState() {
    super.initState();
    _loadExistingServiceData();
  }

  Future<void> _selectDate(BuildContext context, String key) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dates[key] ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dates[key]) {
      setState(() {
        _dates[key] = picked;
      });
    }
  }

  Future<void> _loadExistingServiceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final vehicleId = widget.vehicleData?['vehicle_id'];

    QuerySnapshot serviceQuery;
    String? maintenanceId;
    String? usedVehicleId;

    if (vehicleId != null && vehicleId.toString().isNotEmpty) {
      final maintenanceQuery = await FirebaseFirestore.instance
          .collection('maintenance')
          .where('user_id', isEqualTo: userId)
          .where('vehicle_id', isEqualTo: vehicleId)
          .limit(1)
          .get();

      if (maintenanceQuery.docs.isEmpty) return;

      maintenanceId = maintenanceQuery.docs.first.id;

      serviceQuery = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: userId)
          .where('vehicle_id', isEqualTo: vehicleId)
          .where('maintenance_id', isEqualTo: maintenanceId)
          .limit(1)
          .get();

      usedVehicleId = vehicleId;
    } else {
      serviceQuery = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: false)
          .limit(1)
          .get();

      if (serviceQuery.docs.isEmpty) return;

      final serviceData = serviceQuery.docs.first.data() as Map<String, dynamic>;
      usedVehicleId = serviceData['vehicle_id'];
      maintenanceId = serviceData['maintenance_id'];
    }

    if (serviceQuery.docs.isNotEmpty) {
      final data = serviceQuery.docs.first.data() as Map<String, dynamic>?;

      setState(() {
        currentVehicleId = usedVehicleId;
        currentMaintenanceId = maintenanceId;

        _dates['insurance_expiry_date'] =
            (data?['insurance_expiry_date'] as Timestamp?)?.toDate();
        _dates['next_oil_change'] =
            (data?['next_oil_change'] as Timestamp?)?.toDate();
        _dates['next_tire_replace'] =
            (data?['next_tire_replace'] as Timestamp?)?.toDate();
        _dates['next_service'] =
            (data?['next_service'] as Timestamp?)?.toDate();
      });
    }
  }

  Future<void> _saveServiceSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isSaving = true);

    final userId = user.uid;
    final vehicleId = currentVehicleId;

    if (vehicleId == null || currentMaintenanceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid vehicle or maintenance data found")),
      );
      setState(() => isSaving = false);
      return;
    }

    final serviceQuery = await FirebaseFirestore.instance
        .collection('service')
        .where('user_id', isEqualTo: userId)
        .where('vehicle_id', isEqualTo: vehicleId)
        .where('maintenance_id', isEqualTo: currentMaintenanceId)
        .limit(1)
        .get();

    if (serviceQuery.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('service')
          .doc(serviceQuery.docs.first.id)
          .update({
        'insurance_expiry_date': _dates['insurance_expiry_date'],
        'next_oil_change': _dates['next_oil_change'],
        'next_tire_replace': _dates['next_tire_replace'],
        'next_service': _dates['next_service'],
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      await FirebaseFirestore.instance.collection('service').add({
        'user_id': userId,
        'vehicle_id': vehicleId,
        'maintenance_id': currentMaintenanceId,
        'insurance_expiry_date': _dates['insurance_expiry_date'],
        'next_oil_change': _dates['next_oil_change'],
        'next_tire_replace': _dates['next_tire_replace'],
        'next_service': _dates['next_service'],
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    // Now set reminders for all upcoming service dates
    final notiService = NotiService();
    await notiService.init();

    final now = DateTime.now();
    Map<String, String> messages = {
      'insurance_expiry_date': '🛡️ Insurance is about to expire!',
      'next_oil_change': '🛢️ Time for your next oil change!',
      'next_tire_replace': '🛞 Time to replace your tires!',
      'next_service': '🔧 Time for vehicle servicing!',
    };

    int notificationId = 0;
    for (var key in _dates.keys) {
      final date = _dates[key];
      if (date != null && date.isAfter(now)) {
        // Schedule a reminder notification
        await notiService.showNotification(
          id: notificationId++,
          title: "Service Reminder",
          body: messages[key] ?? "Vehicle maintenance reminder",
        );
      }
    }

    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Service schedule saved and reminders set.")),
    );
  }

  Widget _buildDateTile(String label, String key) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        _dates[key] != null
            ? DateFormat.yMMMd().format(_dates[key]!): 'Select Date',
        style: TextStyle(color: Colors.grey[300]),
      ),
      trailing: const Icon(Icons.calendar_today, color: Colors.white),
      tileColor: Colors.grey[850],
      onTap: () => _selectDate(context, key),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Service Schedule"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isSaving ? null : _saveServiceSchedule,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDateTile("Insurance Expiry Date", "insurance_expiry_date"),
              _buildDateTile("Next Oil Change", "next_oil_change"),
              _buildDateTile("Next Tire Replace", "next_tire_replace"),
              _buildDateTile("Next Service", "next_service"),
              const SizedBox(height: 20),

              // 🔔 REMINDER BUTTON
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.notifications),
                label: const Text("Set Reminder"),
                onPressed: () async {
                  final notiService = NotiService();
                  await notiService.init();

                  final now = DateTime.now();
                  Map<String, String> messages = {
                    'insurance_expiry_date': '🛡️ Insurance is about to expire!',
                    'next_oil_change': '🛢️ Time for your next oil change!',
                    'next_tire_replace': '🛞 Time to replace your tires!',
                    'next_service': '🔧 Time for vehicle servicing!',
                  };

                  int notificationId = 0;
                  for (var key in _dates.keys) {
                    final date = _dates[key];
                    if (date != null && date.isAfter(now)) {
                      await notiService.showNotification(
                        id: notificationId++,
                        title: "Service Reminder",
                        body: messages[key] ?? "Vehicle maintenance reminder",
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
