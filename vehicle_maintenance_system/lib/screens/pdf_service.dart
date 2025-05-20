import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);

class PdfService {
  static Future<pw.Document> generateVehicleReport({
    required Map<String, dynamic> vehicleData,
    required Map<String, dynamic> maintenanceData,
    required Map<String, dynamic> serviceData,
    required Uint8List? vehicleImage,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final textStyle = pw.TextStyle(fontSize: 12, color: PdfColors.white);
    final headerStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    final sectionHeaderStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(kYellow.value));

    // Load font
    final font = await rootBundle.load("assets/fonts/Roboto/Roboto-VariableFont_wdth,wght.ttf");
    final ttf = pw.Font.ttf(font);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) => [
          // Header with vehicle image
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(kDarkCard.value),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
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
                      '${vehicleData['model']} Report',
                      style: sectionHeaderStyle,
                    ),
                    pw.Text(
                      vehicleData['vehicle_number'] ?? '',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Vehicle Information Section
          _buildSection(
            title: 'Vehicle Information',
            lastUpdated: vehicleData['updated_at'],
            content: pw.Table(
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
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Maintenance History Section
          _buildSection(
            title: 'Maintenance History',
            lastUpdated: maintenanceData['updated_at'],
            content: pw.Table(
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
          ),
          pw.SizedBox(height: 20),
          
          // Upcoming Services Section
          _buildSection(
            title: 'Upcoming Services',
            lastUpdated: serviceData['updated_at'],
            content: pw.Table(
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
          ),
          
          // Footer
          pw.SizedBox(height: 30),
          pw.Text(
            'Generated on ${dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSection({
    required String title,
    required Timestamp? lastUpdated,
    required pw.Widget content,
  }) {
    final dateFormat = DateFormat('MMM d, y h:mm a');
    
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(kDarkCard.value),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(kYellow.value),
          )),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Last Updated:',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
              pw.Text(
                lastUpdated != null ? dateFormat.format(lastUpdated.toDate()) : 'N/A',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(String label, String? value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            value ?? 'Not specified',
            style: const pw.TextStyle(color: PdfColors.white),
          ),
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
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            date != null ? dateFormat.format(date.toDate()) : 'Not scheduled',
            style: const pw.TextStyle(color: PdfColors.white),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            details,
            style: const pw.TextStyle(color: PdfColors.white),
          ),
        ),
      ],
    );
  }
}