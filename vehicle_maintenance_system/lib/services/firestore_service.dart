import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_vehicle/models/service_model.dart'; // Ensure this import is correct
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch service schedule from Firestore
  Future<ServiceSchedule> getServiceSchedule(String userId) async {
    DocumentSnapshot snapshot =
        await _firestore.collection('vehicles').doc(userId).get();
    if (!snapshot.exists) {
      throw Exception("Vehicle data not found");
    }

    var data = snapshot.data() as Map<String, dynamic>;
    return ServiceSchedule(
      lastTireReplace: data['last_tire_replace'] ?? "2023-01-01",
      lastOilChange: data['last_oil_change'] ?? "2023-01-01",
      lastService: data['last_service'] ?? "2023-01-01",
      insuranceExpiry: data['insurance_expiry'] ?? "2023-01-01",
      insuranceCompany: data['insurance_company'] ?? "N/A",
      insurancePolicyNumber: data['insurance_policy_number'] ?? "N/A",
      otherMaintenance: data['other_maintenance'] ?? "N/A",
    );
  }

  // Automate service updates
  Future<void> automateServiceUpdates(String userId, String vehicleId) async {
    try {
      final schedule = await getServiceSchedule(userId);

      // Update insurance details if expired
      Map<String, dynamic> insuranceUpdates = schedule.updateInsuranceDetails();
      if (insuranceUpdates.isNotEmpty) {
        await _firestore.collection('vehicles').doc(vehicleId).update(insuranceUpdates);
      }

      // Add new maintenance entry
      Map<String, dynamic> maintenanceEntry = schedule.toMaintenanceEntry();
      await _firestore.collection('vehicles').doc(vehicleId).update({
        'maintenance_history': FieldValue.arrayUnion([maintenanceEntry]),
      });

      // Calculate and store future service schedules
      await _calculateAndStoreSchedules(userId, vehicleId, schedule);

    } catch (e) {
      print("Error automating service updates: $e");
    }
  }

  Future<void> _calculateAndStoreSchedules(String userId, String vehicleId, ServiceSchedule schedule) async {
    DateTime? lastTireReplace = _parseDate(schedule.lastTireReplace);
    DateTime? lastOilChange = _parseDate(schedule.lastOilChange);
    DateTime? lastService = _parseDate(schedule.lastService);

    if (lastTireReplace != null) {
      await _storeSchedule(vehicleId, lastTireReplace.add(Duration(days: 365 * 2)), 'Tire Replacement', schedule.otherMaintenance);
    }
    if (lastOilChange != null) {
      await _storeSchedule(vehicleId, lastOilChange.add(Duration(days: 180)), 'Oil Change', schedule.otherMaintenance);
    }
    if (lastService != null) {
      await _storeSchedule(vehicleId, lastService.add(Duration(days: 365)), 'General Service', schedule.otherMaintenance);
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      print("Error parsing date: $e");
      return null;
    }
  }

  Future<void> _storeSchedule(String vehicleId, DateTime scheduleDate, String type, String otherMaintenance) async {
    if (scheduleDate.isBefore(DateTime.now())) return;

    await _firestore.collection('vehicles').doc(vehicleId).update({
      'maintenance_history': FieldValue.arrayUnion([
        {
          'type': type,
          'date': scheduleDate.toIso8601String(),
          'details': 'Scheduled',
          'timestamp': FieldValue.serverTimestamp(),
          'other_maintenance': otherMaintenance,
        }
      ])
    });
  }
}

// Background task for scheduled service updates
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == "serviceUpdates") {
        final userId = inputData?['userId'];
        if (userId == null || userId.isEmpty) return false;

        final firestoreService = FirestoreService();
        final vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(userId)
            .get();

        if (!vehicleSnapshot.exists) return false;

        await firestoreService.automateServiceUpdates(userId, vehicleSnapshot.id);
        return true;
      }
      return false;
    } catch (e) {
      print("Background task failed: $e");
      return false;
    }
  });
}