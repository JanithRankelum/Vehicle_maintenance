// report_screen.dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'pdf_service.dart';

class ReportScreen extends StatefulWidget {
  final String vehicleId;

  const ReportScreen({super.key, required this.vehicleId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool isLoading = false;
  Map<String, dynamic>? vehicleData;
  Map<String, dynamic>? maintenanceData;
  Map<String, dynamic>? serviceData;
  Uint8List? vehicleImage;
  final dateFormat = DateFormat('MMM d, y h:mm a');

  // Map vehicle models to image asset paths
  final Map<String, String> vehicleImages = {
    'Model S': 'assets/images/tesla_model_s.jpg',
    'Model 3': 'assets/images/tesla_model_3.jpg',
    'Model X': 'assets/images/tesla_model_x.jpg',
    'Model Y': 'assets/images/tesla_model_y.jpg',
    // Add more models as needed
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        // Fetch vehicle data
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .get();
        vehicleData = vehicleDoc.data();

        // Load vehicle image
        if (vehicleData != null && vehicleData!['model'] != null) {
          final imagePath = vehicleImages[vehicleData!['model']];
          if (imagePath != null) {
            final byteData = await rootBundle.load(imagePath);
            vehicleImage = byteData.buffer.asUint8List();
          }
        }

        // Fetch maintenance data
        final maintenanceQuery = await FirebaseFirestore.instance
            .collection('maintenance')
            .where('user_id', isEqualTo: user.uid)
            .where('vehicle_id', isEqualTo: widget.vehicleId)
            .limit(1)
            .get();
        maintenanceData = maintenanceQuery.docs.isNotEmpty 
            ? maintenanceQuery.docs.first.data() 
            : {};

        // Fetch service data
        final serviceQuery = await FirebaseFirestore.instance
            .collection('service')
            .where('user_id', isEqualTo: user.uid)
            .where('vehicle_id', isEqualTo: widget.vehicleId)
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

  Future<void> _generateAndSavePdf() async {
    if (vehicleData == null || maintenanceData == null || serviceData == null) {
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
        vehicleData: vehicleData!,
        maintenanceData: maintenanceData!,
        serviceData: serviceData!,
        vehicleImage: vehicleImage,
      );

      // Save the PDF file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/vehicle_report_${widget.vehicleId}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: isLoading ? null : _generateAndSavePdf,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Header with Image
                  _buildVehicleHeader(),
                  const SizedBox(height: 20),
                  
                  // Vehicle Information Section
                  _buildSection(
                    title: 'Vehicle Information',
                    lastUpdated: vehicleData?['updated_at'],
                    children: [
                      _buildInfoTile('Model', vehicleData?['model']),
                      _buildInfoTile('Vehicle Number', vehicleData?['vehicle_number']),
                      _buildInfoTile('Vehicle Type', vehicleData?['vehicle_type']),
                      _buildInfoTile('Company', vehicleData?['vehicle_company']),
                      _buildInfoTile('Fuel Type', vehicleData?['fuel_type']),
                      _buildInfoTile('Year', vehicleData?['year']?.toString()),
                      _buildInfoTile('Chassis Number', vehicleData?['chassis_number']),
                      _buildInfoTile('Engine Number', vehicleData?['engine_number']),
                      _buildInfoTile('Registration Number', vehicleData?['registration_number']),
                      _buildInfoTile('Owner Name', vehicleData?['owner_name']),
                    ],
                  ),
                  
                  // Maintenance History Section
                  _buildSection(
                    title: 'Maintenance History',
                    lastUpdated: maintenanceData?['updated_at'],
                    children: [
                      _buildInfoTile('Insurance Company', maintenanceData?['insurance_company']),
                      _buildInfoTile('Policy Number', maintenanceData?['insurance_policy_number']),
                      _buildInfoTile('Last Oil Change', maintenanceData?['last_oil_change']),
                      _buildInfoTile('Last Service', maintenanceData?['last_service']),
                      _buildInfoTile('Last Tire Replacement', maintenanceData?['last_tire_replace']),
                      _buildInfoTile('Other Maintenance', maintenanceData?['other_maintenance']),
                    ],
                  ),
                  
                  // Upcoming Services Section
                  _buildSection(
                    title: 'Upcoming Services',
                    lastUpdated: serviceData?['updated_at'],
                    children: [
                      _buildServiceTile(
                        'Insurance Expiry',
                        serviceData?['insurance_expiry_date'],
                        '${serviceData?['insurance_company'] ?? ''} (${serviceData?['insurance_policy_number'] ?? ''})'
                      ),
                      _buildServiceTile(
                        'Oil Change',
                        serviceData?['next_oil_change'],
                        '${serviceData?['oil_brand'] ?? ''} ${serviceData?['oil_viscosity'] ?? ''} • ${serviceData?['recommended_mileage']?.toString() ?? '0'} km'
                      ),
                      _buildServiceTile(
                        'Tire Replacement',
                        serviceData?['next_tire_replace'],
                        '${serviceData?['tire_brand'] ?? ''} • ${serviceData?['tire_recommended_mileage']?.toString() ?? '0'} km'
                      ),
                      _buildServiceTile(
                        'Service',
                        serviceData?['next_service'],
                        '${serviceData?['service_type'] ?? ''}\n${serviceData?['other_maintenance'] ?? ''}'
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVehicleHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    '${vehicleData?['model'] ?? 'Vehicle'} Report',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicleData?['vehicle_number'] ?? '',
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
    );
  }

  Widget _buildSection({
    required String title,
    required Timestamp? lastUpdated,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Updated: ${lastUpdated != null ? dateFormat.format(lastUpdated.toDate()) : 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value ?? 'Not specified'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(String service, Timestamp? date, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  service,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  date != null ? dateFormat.format(date.toDate()) : 'Not scheduled',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}