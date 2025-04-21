import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class VehicleListScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vehicles',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: kBackground,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('user_id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error fetching vehicles",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: kYellow),
            );
          }

          final vehicles = snapshot.data!.docs;

          if (vehicles.isEmpty) {
            return Center(
              child: Text(
                "No vehicles added yet.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              itemCount: vehicles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = vehicles[index];
                final data = doc.data() as Map<String, dynamic>;
                data['vehicle_id'] = doc.id;

                return Container(
                  decoration: BoxDecoration(
                    color: kDarkCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                    leading: Icon(Icons.directions_car, color: kYellow),
                    title: Text(
                      data['model'] ?? 'Unknown Model',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      data['vehicle_number'] ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Icon(Icons.chevron_right, color: kYellow),
                    onTap: () {
                      Navigator.pop(context, data);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}