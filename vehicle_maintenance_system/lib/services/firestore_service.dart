import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Add Vehicle (using user subcollection for better organization)
  Future<void> addVehicle(String userId, Map<String, dynamic> vehicleData) async {
    try {
      await _firestore.collection('users').doc(userId).collection('vehicles').add(vehicleData);
    } catch (e) {
      print("Error adding vehicle: $e");
      rethrow; // Re-throw the error to be handled by the caller
    }
  }

  // 2. Check if User Has a Vehicle
  Future<bool> hasVehicle(String userId) async {
    try {
      var snapshot = await _firestore.collection('users').doc(userId).collection('vehicles').get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking for vehicle: $e");
      rethrow;
    }
  }

  // 3. Get Vehicle Stream (for real-time updates)
  Stream<QuerySnapshot> getVehiclesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .snapshots();
  }

  // 4. Get Vehicle Data (single document)
  Future<DocumentSnapshot?> getVehicleData(String userId, String vehicleId) async {
    try {
      return await _firestore.collection('users').doc(userId).collection('vehicles').doc(vehicleId).get();
    } catch (e) {
      print("Error getting vehicle data: $e");
      rethrow;
    }
  }

  // 5. Update Vehicle Data
  Future<void> updateVehicleData(String userId, String vehicleId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).collection('vehicles').doc(vehicleId).update(data);
    } catch (e) {
      print("Error updating vehicle data: $e");
      rethrow;
    }
  }

    // 6. Delete Vehicle
  Future<void> deleteVehicle(String userId, String vehicleId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('vehicles').doc(vehicleId).delete();
    } catch (e) {
      print("Error deleting vehicle: $e");
      rethrow;
    }
  }

}