import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleListScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Vehicles"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('user_id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error fetching vehicles"));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          final vehicles = snapshot.data!.docs;

          if (vehicles.isEmpty) {
            return Center(child: Text("No vehicles added yet.", style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final data = vehicles[index].data() as Map<String, dynamic>;
              return Card(
                color: Colors.grey[850],
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("Model: ${data['model'] ?? 'Unknown'}", style: TextStyle(color: Colors.white)),
                  subtitle: Text("Vehicle Number: ${data['vehicle_number'] ?? ''}", style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    // Return the selected vehicle data to HomeScreen
                    Navigator.pop(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
