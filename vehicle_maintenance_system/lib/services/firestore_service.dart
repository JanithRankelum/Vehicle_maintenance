import 'package:cloud_firestore/cloud_firestore.dart';


  class FirestoreService {
  // Add your Firestore methods here

  Stream<QuerySnapshot> getVehicles(String userId) {
    return FirebaseFirestore.instance
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .snapshots();
}
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save Vehicle Data to Firestore
  Future<void> addVehicle(String userId, Map<String, dynamic> vehicleData) async {
    try {
      await _db.collection('users').doc(userId).collection('vehicles').add(vehicleData);
    } catch (e) {
      print("Error adding vehicle: $e");
      throw e;
    }
  }

  // Check if the user has a vehicle
  Future<bool> hasVehicle(String userId) async {
    var snapshot = await _db.collection('users').doc(userId).collection('vehicles').get();
    return snapshot.docs.isNotEmpty;
  }
}
