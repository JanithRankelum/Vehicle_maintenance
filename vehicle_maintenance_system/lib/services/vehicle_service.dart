import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_vehicle/models/vehicle_model.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add Vehicle
  Future<void> addVehicle(Vehicle vehicle) async {
    await _firestore.collection('vehicles').add({
      ...vehicle.toMap(),
      'userId': _auth.currentUser?.uid,
    });
  }

  // Get User's Vehicle
  Future<Vehicle?> getUserVehicle() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final snapshot = await _firestore
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Vehicle.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }
}
