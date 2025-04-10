import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:dr_vehicle/screens/local_notifications.dart'; // Adjust path if needed

class ServiceSchedulePage extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const ServiceSchedulePage({super.key, required this.vehicleData});

  @override
  State<ServiceSchedulePage> createState() => _ServiceSchedulePageState();
}

class _ServiceSchedulePageState extends State<ServiceSchedulePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nextOilChangeController = TextEditingController();
  final _nextTireReplaceController = TextEditingController();
  final _nextServiceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    _autoCalculateNextDates();
  }

  void _initNotifications() async {
    await LocalNotifications.init();
  }

  void _autoCalculateNextDates() {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final lastOilStr = widget.vehicleData['last_oil_change'];
    final lastTireStr = widget.vehicleData['last_tire_replace'];
    final lastServiceStr = widget.vehicleData['last_service'];

    final lastOil = DateTime.tryParse(lastOilStr ?? '');
    final lastTire = DateTime.tryParse(lastTireStr ?? '');
    final lastService = DateTime.tryParse(lastServiceStr ?? '');

    final nextOil = lastOil?.add(Duration(days: 180));
    final nextTire = lastTire?.add(Duration(days: 730));
    final nextService = lastService?.add(Duration(days: 180));

    if (nextOil != null) _nextOilChangeController.text = dateFormat.format(nextOil);
    if (nextTire != null) _nextTireReplaceController.text = dateFormat.format(nextTire);
    if (nextService != null) _nextServiceController.text = dateFormat.format(nextService);
  }

  Future<void> _scheduleReminder(String title, String body, DateTime date, int id) async {
    final tzDate = tz.TZDateTime.from(date.subtract(Duration(days: 7)), tz.local);

    await LocalNotifications.flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vehicle_service',
          'Vehicle Service Reminders',
          channelDescription: 'Reminders for vehicle service schedules',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> _saveSchedule() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final nextOil = DateTime.parse(_nextOilChangeController.text);
      final nextTire = DateTime.parse(_nextTireReplaceController.text);
      final nextService = DateTime.parse(_nextServiceController.text);

      final docId = widget.vehicleData['id'];
      if (docId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Document ID missing from vehicle data.")),
        );
        return;
      }

      await _firestore.collection('vehicles').doc(uid).collection('vehicles').doc(docId).update({
        'next_oil_change': _nextOilChangeController.text,
        'next_tire_replace': _nextTireReplaceController.text,
        'next_service': _nextServiceController.text,
        'service_schedule_updated_at': Timestamp.now(),
      });

      await _scheduleReminder("Oil Change", "Time to change your oil!", nextOil, 1);
      await _scheduleReminder("Tire Replacement", "Time to replace tires!", nextTire, 2);
      await _scheduleReminder("General Service", "Time for general service!", nextService, 3);

      await LocalNotifications.showSimpleNotification(
        title: "Reminders Set",
        body: "Service schedule saved & reminders activated.",
        payload: "vehicle_service",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Service schedule saved!")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Error saving schedule: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving schedule.")),
      );
    }
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      },
    );
  }

  @override
  void dispose() {
    _nextOilChangeController.dispose();
    _nextTireReplaceController.dispose();
    _nextServiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Service Schedule")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDateField("Next Oil Change", _nextOilChangeController),
            SizedBox(height: 16),
            _buildDateField("Next Tire Replacement", _nextTireReplaceController),
            SizedBox(height: 16),
            _buildDateField("Next General Service", _nextServiceController),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveSchedule,
              child: Text("Save & Set Reminders"),
            ),
          ],
        ),
      ),
    );
  }
}
