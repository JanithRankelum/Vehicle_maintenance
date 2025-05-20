// pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static Future<pw.Document> generateVehicleReport({
    required Map<String, dynamic> vehicleData,
    required Map<String, dynamic> maintenanceData,
    required Map<String, dynamic> serviceData,
    required Uint8List? vehicleImage,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final textStyle = pw.TextStyle(fontSize: 12);
    final headerStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final sectionHeaderStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);

    // Load font
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) => [
          // Header with vehicle image
          pw.Row(
            children: [
              if (vehicleImage != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    image: pw.DecorationImage(
                      image: pw.MemoryImage(vehicleImage),
                      fit: pw.BoxFit.cover,
                    ),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                ),
              pw.SizedBox(width: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Vehicle Maintenance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${vehicleData['model']} • ${vehicleData['vehicle_number']}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Vehicle Information Section
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Vehicle Information', style: sectionHeaderStyle),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    _buildTableRow('Model', vehicleData['model']),
                    _buildTableRow('Vehicle Number', vehicleData['vehicle_number']),
                    _buildTableRow('Vehicle Type', vehicleData['vehicle_type']),
                    _buildTableRow('Company', vehicleData['vehicle_company']),
                    _buildTableRow('Fuel Type', vehicleData['fuel_type']),
                    _buildTableRow('Year', vehicleData['year']?.toString()),
                    _buildTableRow('Chassis Number', vehicleData['chassis_number']),
                    _buildTableRow('Engine Number', vehicleData['engine_number']),
                    _buildTableRow('Registration Number', vehicleData['registration_number']),
                    _buildTableRow('Owner Name', vehicleData['owner_name']),
                    _buildTableRow(
                      'Last Updated',
                      vehicleData['updated_at'] != null
                          ? dateFormat.format((vehicleData['updated_at'] as Timestamp).toDate())
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Maintenance History Section
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Maintenance History', style: sectionHeaderStyle),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Last Updated: ${maintenanceData['updated_at'] != null ? dateFormat.format((maintenanceData['updated_at'] as Timestamp).toDate()) : 'N/A'}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    _buildTableRow('Insurance Company', maintenanceData['insurance_company']),
                    _buildTableRow('Policy Number', maintenanceData['insurance_policy_number']),
                    _buildTableRow('Last Oil Change', maintenanceData['last_oil_change']),
                    _buildTableRow('Last Service', maintenanceData['last_service']),
                    _buildTableRow('Last Tire Replacement', maintenanceData['last_tire_replace']),
                    _buildTableRow('Other Maintenance', maintenanceData['other_maintenance']),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Upcoming Services Section
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Upcoming Services', style: sectionHeaderStyle),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Last Updated: ${serviceData['updated_at'] != null ? dateFormat.format((serviceData['updated_at'] as Timestamp).toDate()) : 'N/A'}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    _buildServiceTableRow(
                      'Insurance Expiry',
                      serviceData['insurance_expiry_date'],
                      '${serviceData['insurance_company'] ?? ''} (${serviceData['insurance_policy_number'] ?? ''})'
                    ),
                    _buildServiceTableRow(
                      'Oil Change',
                      serviceData['next_oil_change'],
                      '${serviceData['oil_brand'] ?? ''} ${serviceData['oil_viscosity'] ?? ''} • ${serviceData['recommended_mileage']?.toString() ?? '0'} km'
                    ),
                    _buildServiceTableRow(
                      'Tire Replacement',
                      serviceData['next_tire_replace'],
                      '${serviceData['tire_brand'] ?? ''} • ${serviceData['tire_recommended_mileage']?.toString() ?? '0'} km'
                    ),
                    _buildServiceTableRow(
                      'Service',
                      serviceData['next_service'],
                      '${serviceData['service_type'] ?? ''}\n${serviceData['other_maintenance'] ?? ''}'
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Footer
          pw.SizedBox(height: 30),
          pw.Text(
            'Generated on ${dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.TableRow _buildTableRow(String label, String? value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(value ?? 'Not specified'),
        ),
      ],
    );
  }

  static pw.TableRow _buildServiceTableRow(String service, Timestamp? date, String details) {
    final dateFormat = DateFormat('MMM d, y h:mm a');
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            service,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            date != null ? dateFormat.format(date.toDate()) : 'Not scheduled',
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(details),
        ),
      ],
    );
  }
}