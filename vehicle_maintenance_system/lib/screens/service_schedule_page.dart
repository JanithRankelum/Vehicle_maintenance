import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dr_vehicle/screens/noti_service.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class ServiceSchedulePage extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const ServiceSchedulePage({super.key, required this.vehicleData});

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
  late String currentVehicleId;
  String? currentMaintenanceId;

  @override
  void initState() {
    super.initState();
    currentVehicleId = widget.vehicleData['vehicle_id'] ?? '';
    _loadExistingServiceData();
  }

  Future<void> _selectDate(BuildContext context, String key) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dates[key] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kYellow,
              onPrimary: Colors.black,
              surface: kDarkCard,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: kBackground,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dates[key]) {
      setState(() => _dates[key] = picked);
    }
  }

  Future<void> _loadExistingServiceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final maintenanceQuery = await FirebaseFirestore.instance
          .collection('maintenance')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .limit(1)
          .get();

      if (maintenanceQuery.docs.isEmpty) return;

      currentMaintenanceId = maintenanceQuery.docs.first.id;

      final serviceQuery = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .where('maintenance_id', isEqualTo: currentMaintenanceId)
          .limit(1)
          .get();

      if (serviceQuery.docs.isNotEmpty) {
        final data = serviceQuery.docs.first.data();
        setState(() {
          _dates['insurance_expiry_date'] = data['insurance_expiry_date']?.toDate();
          _dates['next_oil_change'] = data['next_oil_change']?.toDate();
          _dates['next_tire_replace'] = data['next_tire_replace']?.toDate();
          _dates['next_service'] = data['next_service']?.toDate();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading service data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveServiceSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isSaving = true);

    try {
      final serviceQuery = await FirebaseFirestore.instance
          .collection('service')
          .where('user_id', isEqualTo: user.uid)
          .where('vehicle_id', isEqualTo: currentVehicleId)
          .where('maintenance_id', isEqualTo: currentMaintenanceId)
          .limit(1)
          .get();

      if (serviceQuery.docs.isNotEmpty) {
        await serviceQuery.docs.first.reference.update({
          'insurance_expiry_date': _dates['insurance_expiry_date'],
          'next_oil_change': _dates['next_oil_change'],
          'next_tire_replace': _dates['next_tire_replace'],
          'next_service': _dates['next_service'],
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('service').add({
          'user_id': user.uid,
          'vehicle_id': currentVehicleId,
          'maintenance_id': currentMaintenanceId,
          'insurance_expiry_date': _dates['insurance_expiry_date'],
          'next_oil_change': _dates['next_oil_change'],
          'next_tire_replace': _dates['next_tire_replace'],
          'next_service': _dates['next_service'],
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await _setReminders();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service schedule saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _setReminders() async {
    final notiService = NotiService();
    await notiService.init();

    final now = DateTime.now();
    final vehicleModel = widget.vehicleData['model'] ?? 'your vehicle';
    final vehicleNumber = widget.vehicleData['vehicle_number'] ?? '';

    Map<String, Map<String, String>> reminders = {
      'insurance_expiry_date': {
        'title': '🛡️ Insurance Expiry Reminder',
        'body': 'Insurance for $vehicleModel ($vehicleNumber) expires soon!'
      },
      'next_oil_change': {
        'title': '🛢️ Oil Change Reminder',
        'body': 'Time to change oil for $vehicleModel ($vehicleNumber)'
      },
      'next_tire_replace': {
        'title': '𖣐 Tire Replacement Reminder',
        'body': 'Time to replace tires on $vehicleModel ($vehicleNumber)'
      },
      'next_service': {
        'title': '🛠️ Service Reminder',
        'body': 'Scheduled service for $vehicleModel ($vehicleNumber)'
      },
    };

    for (var key in _dates.keys) {
      final date = _dates[key];
      if (date != null && date.isAfter(now)) {
        final reminderDate = date.subtract(const Duration(days: 14));
        if (reminderDate.isAfter(now)) {
          await notiService.scheduleVehicleNotification(
            vehicleId: currentVehicleId,
            serviceType: key,
            scheduledDate: reminderDate,
            title: reminders[key]!['title']!,
            body: reminders[key]!['body']!,
          );
        }
      }
    }
  }

  Widget _buildDateTile(String label, String key) {
    return Container(
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          label,
          style: TextStyle(
            color: kYellow,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _dates[key] != null 
                ? DateFormat('MMM d, y').format(_dates[key]!)
                : 'Not scheduled',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        trailing: Icon(Icons.calendar_today, color: kYellow),
        onTap: () => _selectDate(context, key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(
          'Service Schedule - ${widget.vehicleData['model']}',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              color: kYellow,
            ),
            onPressed: isSaving ? null : _saveServiceSchedule,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildDateTile("Insurance Expiry Date", "insurance_expiry_date"),
              _buildDateTile("Next Oil Change", "next_oil_change"),
              _buildDateTile("Next Tire Replacement", "next_tire_replace"),
              _buildDateTile("Next Service", "next_service"),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.notifications_active),
                label: const Text(
                  "SET REMINDERS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _setReminders,
              ),
              if (isSaving)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: kYellow),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}