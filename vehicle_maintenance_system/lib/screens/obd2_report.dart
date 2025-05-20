import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class OBD2ReportPage extends StatelessWidget {
  const OBD2ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: Text(
            'Please login to view reports',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'VEHICLE REPORTS',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('predictions')
            .orderBy('timestamp', descending: true) // Newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No reports found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp;
              final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a')
                  .format(timestamp.toDate());

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: kDarkCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    '${data['vehicleName']} (${data['vehicleNumber']})',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    formattedDate,
                    style: TextStyle(color: Colors.white70),
                  ),
                  leading: Icon(
                    Icons.car_repair,
                    color: kYellow,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReportItem(
                            'Engine Status',
                            data['engineHealth'] == "1" ? "GOOD" : "NEEDS ATTENTION",
                            data['engineHealth'] == "1" ? Colors.green : Colors.red,
                          ),
                          const SizedBox(height: 12),
                          _buildReportItem(
                            'Fuel Consumption',
                            '${data['fuelConsumption']}%',
                            _getFuelConsumptionColor(data['fuelConsumption']),
                          ),
                          const SizedBox(height: 12),
                          _buildReportItem(
                            'Mileage',
                            '${data['mileage']} MPG',
                            _getMileageColor(data['mileage']),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReportItem(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getFuelConsumptionColor(dynamic value) {
    final consumption = double.tryParse(value.toString()) ?? 0.0;
    if (consumption <= 30) return Colors.green;
    if (consumption <= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getMileageColor(dynamic value) {
    final mileage = double.tryParse(value.toString()) ?? 0.0;
    if (mileage <= 80) return Colors.red;
    if (mileage <= 160) return Colors.orange;
    return Colors.green;
  }
}