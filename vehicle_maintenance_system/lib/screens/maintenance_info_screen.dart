import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class MaintenanceInfoScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const MaintenanceInfoScreen({super.key, required this.vehicleData});

  @override
  State<MaintenanceInfoScreen> createState() => _MaintenanceInfoScreenState();
}

class _MaintenanceInfoScreenState extends State<MaintenanceInfoScreen> {
  Map<String, dynamic>? updatedData;
  Map<String, dynamic>? serviceData;
  bool isLoading = true;
  String? docId;
  String? serviceDocId;

  @override
  void initState() {
    super.initState();
    fetchMaintenanceData();
    fetchServiceData();
  }

  Future<void> fetchMaintenanceData() async {
    final user = FirebaseAuth.instance.currentUser;
    final vehicleId =
        widget.vehicleData['vehicle_id'] ?? widget.vehicleData['id'];

    if (user != null && vehicleId != null) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('maintenance')
            .where('user_id', isEqualTo: user.uid)
            .where('vehicle_id', isEqualTo: vehicleId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          setState(() {
            docId = doc.id;
            updatedData = doc.data();
          });
        } else {
          setState(() {
            updatedData = {
              'insurance_company': '',
              'insurance_policy_number': '',
              'last_oil_change': '',
              'last_service': '',
              'last_tire_replace': '',
              'other_maintenance': '',
              'updated_at': null,
            };
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading maintenance data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchServiceData() async {
    final user = FirebaseAuth.instance.currentUser;
    final vehicleId =
        widget.vehicleData['vehicle_id'] ?? widget.vehicleData['id'];

    if (user != null && vehicleId != null) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('service')
            .where('user_id', isEqualTo: user.uid)
            .where('vehicle_id', isEqualTo: vehicleId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          setState(() {
            serviceDocId = doc.id;
            serviceData = doc.data();
            isLoading = false;
          });
        } else {
          setState(() {
            serviceData = {
              'insurance_expiry_date': null,
              'next_oil_change': null,
              'next_tire_replace': null,
              'next_service': null,
              'oil_brand': '',
              'oil_viscosity': '',
              'recommended_mileage': 0,
              'tire_brand': '',
              'tire_recommended_mileage': 0,
              'service_type': '',
              'other_maintenance': '',
              'updated_at': null,
              'last_updated_insurance': null,
              'last_updated_oil': null,
              'last_updated_tire': null,
              'last_updated_service': null,
            };
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading service data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not updated yet';
    return DateFormat('MMM d, y h:mm a').format(timestamp.toDate());
  }

  Widget _buildServiceDetailCard({
    required String title,
    String? value,
    required Timestamp? serviceDate,
    required Timestamp? lastUpdated,
  }) {
    final isOverdue =
        serviceDate != null && serviceDate.toDate().isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red[900]?.withOpacity(0.3) : kDarkCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            title: Text(
              title,
              style: TextStyle(
                color: kYellow,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (value != null && value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled: ${_formatTimestamp(serviceDate)}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red[300] : Colors.white,
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last Updated: ${_formatTimestamp(lastUpdated)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'OVERDUE!',
                      style: TextStyle(
                        color: Colors.red[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || updatedData == null || serviceData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Maintenance Info',
            style: TextStyle(color: kYellow, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kBackground,
          centerTitle: true,
          elevation: 0,
        ),
        backgroundColor: kBackground,
        body: Center(
          child: CircularProgressIndicator(color: kYellow),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maintenance Details',
          style: TextStyle(color: kYellow, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: kBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Maintenance History Section
            const Text(
              'Maintenance History',
              style: TextStyle(
                color: kYellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              "Insurance Company",
              updatedData?['insurance_company'] ?? 'Not specified',
              _formatTimestamp(serviceData?['last_updated_insurance']),
            ),
            _buildInfoTile(
              "Insurance Policy Number",
              updatedData?['insurance_policy_number'] ?? 'Not specified',
              _formatTimestamp(serviceData?['last_updated_insurance']),
            ),
            _buildInfoTile(
              "Last Oil Change",
              updatedData?['last_oil_change'] ?? 'Not specified',
              _formatTimestamp(serviceData?['last_updated_oil']),
            ),
            _buildInfoTile(
              "Last Service",
              updatedData?['last_service'] ?? 'Not specified',
              _formatTimestamp(serviceData?['last_updated_service']),
            ),
            _buildInfoTile(
              "Last Tire Replacement",
              updatedData?['last_tire_replace'] ?? 'Not specified',
              _formatTimestamp(serviceData?['last_updated_tire']),
            ),
            _buildInfoTile(
              "Other Maintenance",
              updatedData?['other_maintenance'] ?? 'Not specified',
              _formatTimestamp(serviceData?['last_updated_service']),
            ),

            // Upcoming Services Section
            const SizedBox(height: 24),
            const Text(
              'Maintenance & Upcoming Services',
              style: TextStyle(
                color: kYellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildServiceDetailCard(
              title: "Insurance Expiry",
              value: serviceData?['insurance_company'] != null
                  ? "${serviceData?['insurance_company']} (${serviceData?['insurance_policy_number']})"
                  : null,
              serviceDate: serviceData?['insurance_expiry_date'],
              lastUpdated: serviceData?['last_updated_insurance'],
            ),
            _buildServiceDetailCard(
              title: "Next Oil Change",
              value: serviceData?['oil_brand'] != null
                  ? "${serviceData?['oil_brand']} (${serviceData?['oil_viscosity']}) - ${serviceData?['recommended_mileage']} km"
                  : null,
              serviceDate: serviceData?['next_oil_change'],
              lastUpdated: serviceData?['last_updated_oil'],
            ),
            _buildServiceDetailCard(
              title: "Next Tire Replacement",
              value: serviceData?['tire_brand'] != null
                  ? "${serviceData?['tire_brand']} - ${serviceData?['tire_recommended_mileage']} km"
                  : null,
              serviceDate: serviceData?['next_tire_replace'],
              lastUpdated: serviceData?['last_updated_tire'],
            ),
            _buildServiceDetailCard(
              title: "Next Service",
              value: serviceData?['service_type'] != null
                  ? "${serviceData?['service_type']}${serviceData?['other_maintenance'] != null && serviceData?['other_maintenance'].isNotEmpty ? '\n${serviceData?['other_maintenance']}' : ''}"
                  : null,
              serviceDate: serviceData?['next_service'],
              lastUpdated: serviceData?['last_updated_service'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, String lastUpdated) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            label,
            style: TextStyle(
              color: kYellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Last Updated: $lastUpdated',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
