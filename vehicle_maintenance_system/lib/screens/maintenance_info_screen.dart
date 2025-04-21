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
  bool isEditing = false;
  bool isLoading = true;
  String? docId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchMaintenanceData();
  }

  Future<void> fetchMaintenanceData() async {
    final user = FirebaseAuth.instance.currentUser;
    final vehicleId = widget.vehicleData['vehicle_id'] ?? widget.vehicleData['id'];

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
            isLoading = false;
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
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading maintenance data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMaintenanceInfo() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      final vehicleId = widget.vehicleData['vehicle_id'] ?? widget.vehicleData['id'];

      if (user != null && updatedData != null) {
        try {
          final maintenanceCollection = FirebaseFirestore.instance.collection('maintenance');
          final dataToUpdate = {
            ...updatedData!,
            'updated_at': FieldValue.serverTimestamp(),
            'user_id': user.uid,
            'vehicle_id': vehicleId,
          };

          if (docId != null) {
            await maintenanceCollection.doc(docId).update(dataToUpdate);
          } else {
            final docRef = await maintenanceCollection.add(dataToUpdate);
            docId = docRef.id;
          }

          setState(() => isEditing = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maintenance info updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating maintenance: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoTile(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            label,
            style: TextStyle(
              color: kYellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: isEditing
              ? TextFormField(
                  initialValue: updatedData?[key]?.toString() ?? '',
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter $label",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => updatedData![key] = val,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter $label';
                    }
                    return null;
                  },
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    updatedData?[key]?.toString() ?? 'Not specified',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || updatedData == null) {
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

    Timestamp? timestamp = updatedData!['updated_at'];
    String formattedTime = timestamp != null
        ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
        : 'Not available';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maintenance Details',
          style: TextStyle(color: kYellow, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.save : Icons.edit,
              color: kYellow,
            ),
            onPressed: () {
              if (isEditing) {
                _updateMaintenanceInfo();
              } else {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
      ),
      backgroundColor: kBackground,
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildInfoTile("Insurance Company", "insurance_company"),
              _buildInfoTile("Insurance Policy Number", "insurance_policy_number"),
              _buildInfoTile("Last Oil Change", "last_oil_change"),
              _buildInfoTile("Last Service", "last_service"),
              _buildInfoTile("Last Tire Replacement", "last_tire_replace"),
              _buildInfoTile("Other Maintenance", "other_maintenance"),
              Container(
                decoration: BoxDecoration(
                  color: kDarkCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    "Last Updated",
                    style: TextStyle(
                      color: kYellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _updateMaintenanceInfo,
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}