import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'pdf_service.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class ReportScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const ReportScreen({super.key, required this.vehicleData});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool isLoading = false;
  Map<String, dynamic>? maintenanceData;
  Map<String, dynamic>? serviceData;
  Uint8List? vehicleImage;
  final dateFormat = DateFormat('MMM d, y h:mm a');

  String _getVehicleImage(String? vehicleType) {
    switch (vehicleType?.toLowerCase()) {
      case 'car':
        return 'assets/logo/car.png';
      case 'bike':
        return 'assets/logo/Bike.png';
      case 'truck':
        return 'assets/logo/Truck.png';
      case 'bus':
        return 'assets/logo/Bus.png';
      case 'van':
        return 'assets/logo/Van.png';
      case 'suv':
        return 'assets/logo/Suv.png';
      default:
        return 'assets/logo/car.png';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
    _loadVehicleImage();
  }

  Future<void> _loadAdditionalData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        // Fetch maintenance data
        final maintenanceQuery = await FirebaseFirestore.instance
            .collection('maintenance')
            .where('user_id', isEqualTo: user.uid)
            .where('vehicle_id', isEqualTo: widget.vehicleData['vehicle_id'])
            .limit(1)
            .get();
        maintenanceData = maintenanceQuery.docs.isNotEmpty 
            ? maintenanceQuery.docs.first.data() 
            : {};

        // Fetch service data
        final serviceQuery = await FirebaseFirestore.instance
            .collection('service')
            .where('user_id', isEqualTo: user.uid)
            .where('vehicle_id', isEqualTo: widget.vehicleData['vehicle_id'])
            .limit(1)
            .get();
        serviceData = serviceQuery.docs.isNotEmpty 
            ? serviceQuery.docs.first.data() 
            : {};

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadVehicleImage() async {
    if (widget.vehicleData['vehicle_type'] != null) {
      final imagePath = _getVehicleImage(widget.vehicleData['vehicle_type']);
      final byteData = await rootBundle.load(imagePath);
      setState(() {
        vehicleImage = byteData.buffer.asUint8List();
      });
    }
  }

  Future<void> _generateAndSavePdf() async {
    if (maintenanceData == null || serviceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while data is loading'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final pdf = await PdfService.generateVehicleReport(
        vehicleData: widget.vehicleData,
        maintenanceData: maintenanceData!,
        serviceData: serviceData!,
        vehicleImage: vehicleImage,
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/vehicle_report_${widget.vehicleData['vehicle_id']}.pdf');
      await file.writeAsBytes(await pdf.save());

      await OpenFile.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildInfoTile(String label, String value) {
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
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              value.isNotEmpty ? value : 'Not specified',
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

  Widget _buildInfoTileWithTimestamp(String label, String value, Timestamp? timestamp) {
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
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated: ${timestamp != null ? dateFormat.format(timestamp.toDate()) : 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTileWithTimestamp(String title, Timestamp? date, String details, Timestamp? updatedAt) {
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
            title,
            style: TextStyle(
              color: kYellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date != null ? dateFormat.format(date.toDate()) : 'Not scheduled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated: ${updatedAt != null ? dateFormat.format(updatedAt.toDate()) : 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vehicle Report',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: kYellow),
            onPressed: isLoading ? null : _generateAndSavePdf,
          ),
        ],
      ),
      backgroundColor: kBackground,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kYellow))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Vehicle Header
                  Container(
                    decoration: BoxDecoration(
                      color: kDarkCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          if (vehicleImage != null)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: MemoryImage(vehicleImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.directions_car, size: 40),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.vehicleData['model'] ?? 'Vehicle'} Report',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: kYellow,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.vehicleData['vehicle_number'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Vehicle Information Section
                  _buildInfoTile("Model", widget.vehicleData['model']?.toString() ?? ''),
                  _buildInfoTile("Vehicle Number", widget.vehicleData['vehicle_number']?.toString() ?? ''),
                  _buildInfoTile("Vehicle Type", widget.vehicleData['vehicle_type']?.toString() ?? ''),
                  _buildInfoTile("Company", widget.vehicleData['vehicle_company']?.toString() ?? ''),
                  _buildInfoTile("Fuel Type", widget.vehicleData['fuel_type']?.toString() ?? ''),
                  _buildInfoTile("Year", widget.vehicleData['year']?.toString() ?? ''),
                  _buildInfoTile("Chassis Number", widget.vehicleData['chassis_number']?.toString() ?? ''),
                  _buildInfoTile("Engine Number", widget.vehicleData['engine_number']?.toString() ?? ''),
                  _buildInfoTile("Registration Number", widget.vehicleData['registration_number']?.toString() ?? ''),
                  _buildInfoTile("Owner Name", widget.vehicleData['owner_name']?.toString() ?? ''),

                  // Maintenance History Section
                  if (maintenanceData != null && maintenanceData!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: kDarkCard,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: const Text(
                          'MAINTENANCE HISTORY',
                          style: TextStyle(
                            color: kYellow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Last Updated: ${maintenanceData!['updated_at'] != null ? dateFormat.format(maintenanceData!['updated_at'].toDate()) : 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildInfoTileWithTimestamp(
                      "Insurance Company", 
                      maintenanceData?['insurance_company']?.toString() ?? '',
                      maintenanceData?['insurance_updated_at'],
                    ),
                    _buildInfoTileWithTimestamp(
                      "Policy Number", 
                      maintenanceData?['insurance_policy_number']?.toString() ?? '',
                      maintenanceData?['insurance_updated_at'],
                    ),
                    _buildInfoTileWithTimestamp(
                      "Last Oil Change", 
                      maintenanceData?['last_oil_change']?.toString() ?? '',
                      maintenanceData?['last_oil_change_updated_at'],
                    ),
                    _buildInfoTileWithTimestamp(
                      "Last Service", 
                      maintenanceData?['last_service']?.toString() ?? '',
                      maintenanceData?['last_service_updated_at'],
                    ),
                    _buildInfoTileWithTimestamp(
                      "Last Tire Replacement", 
                      maintenanceData?['last_tire_replace']?.toString() ?? '',
                      maintenanceData?['last_tire_replace_updated_at'],
                    ),
                    _buildInfoTileWithTimestamp(
                      "Other Maintenance", 
                      maintenanceData?['other_maintenance']?.toString() ?? '',
                      maintenanceData?['other_maintenance_updated_at'],
                    ),
                  ],

                  // Upcoming Services Section
                  if (serviceData != null && serviceData!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: kDarkCard,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: const Text(
                          'Maintenance & UPCOMING SERVICES',
                          style: TextStyle(
                            color: kYellow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Last Updated: ${serviceData!['updated_at'] != null ? dateFormat.format(serviceData!['updated_at'].toDate()) : 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildServiceTileWithTimestamp(
                      'Insurance Expiry',
                      serviceData?['insurance_expiry_date'],
                      '${serviceData?['insurance_company'] ?? ''} (${serviceData?['insurance_policy_number'] ?? ''})',
                      serviceData?['insurance_expiry_updated_at'],
                    ),
                    _buildServiceTileWithTimestamp(
                      'Oil Change',
                      serviceData?['next_oil_change'],
                      '${serviceData?['oil_brand'] ?? ''} ${serviceData?['oil_viscosity'] ?? ''} • ${serviceData?['recommended_mileage']?.toString() ?? '0'} km',
                      serviceData?['next_oil_change_updated_at'],
                    ),
                    _buildServiceTileWithTimestamp(
                      'Tire Replacement',
                      serviceData?['next_tire_replace'],
                      '${serviceData?['tire_brand'] ?? ''} • ${serviceData?['tire_recommended_mileage']?.toString() ?? '0'} km',
                      serviceData?['next_tire_replace_updated_at'],
                    ),
                    _buildServiceTileWithTimestamp(
                      'Service',
                      serviceData?['next_service'],
                      '${serviceData?['service_type'] ?? ''}\n${serviceData?['other_maintenance'] ?? ''}',
                      serviceData?['next_service_updated_at'],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}