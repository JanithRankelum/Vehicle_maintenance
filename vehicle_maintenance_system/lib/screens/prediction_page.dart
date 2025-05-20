import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class PredictionPage extends StatelessWidget {
  final String predictionResult;

  const PredictionPage({super.key, required this.predictionResult});

  Future<void> _showSaveDialog(BuildContext context) async {
    final vehicleNameController = TextEditingController();
    final vehicleNumberController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDarkCard,
        title: const Text(
          'Save Vehicle Details',
          style: TextStyle(color: kYellow),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: vehicleNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Vehicle Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kYellow),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kYellow),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: vehicleNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Vehicle Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kYellow),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kYellow),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kYellow)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kYellow),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _saveToFirestore(
                  context,
                  vehicleNameController.text,
                  vehicleNumberController.text,
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToFirestore(
      BuildContext context, String vehicleName, String vehicleNumber) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to save predictions')),
        );
        return;
      }

      final engineHealth = _extractValue("Engine Health", predictionResult);
      final fuelConsumption = double.tryParse(
              _extractValue("Fuel Consumption", predictionResult)) ??
          0.0;
      final mileage =
          double.tryParse(_extractValue("Mileage", predictionResult)) ?? 0.0;

      // Create a batch write to ensure all data is saved atomically
      final batch = FirebaseFirestore.instance.batch();
      
      // Create a reference to a new document
      final predictionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('predictions')
          .doc();

      batch.set(predictionRef, {
        'vehicleName': vehicleName,
        'vehicleNumber': vehicleNumber,
        'engineHealth': engineHealth,
        'fuelConsumption': fuelConsumption,
        'mileage': mileage,
        'timestamp': FieldValue.serverTimestamp(),
        'fullResult': predictionResult,
        'userId': user.uid, // Additional field for easier querying
      });

      // Also update the user document with last prediction time
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      
      batch.update(userRef, {
        'lastPrediction': FieldValue.serverTimestamp(),
        'predictionCount': FieldValue.increment(1),
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prediction saved successfully!')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save prediction: $e')),
      );
    }
  }

  Future<void> _generatePdf(BuildContext context) async {
    final engineHealth = _extractValue("Engine Health", predictionResult);
    final fuelConsumption = double.tryParse(
            _extractValue("Fuel Consumption", predictionResult)) ??
        0.0;
    final mileage =
        double.tryParse(_extractValue("Mileage", predictionResult)) ?? 0.0;

    final isEngineHealthy = engineHealth.trim() == "1";
    final engineStatusText = isEngineHealthy ? "GOOD" : "NEEDS ATTENTION";
    final engineStatusColor = isEngineHealthy ? PdfColor(0, 128, 0) : PdfColor(200, 0, 0);

    // Create PDF document
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final Size pageSize = page.getClientSize();

    // Custom fonts and styles
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    final PdfFont headingFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final PdfFont subHeadingFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final PdfFont normalFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

    // Background rectangle
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(40, 40, 40)),
      bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
    );

    // Header with solid color
    final PdfSolidBrush headerBrush = PdfSolidBrush(PdfColor(45, 45, 45));
    page.graphics.drawRectangle(
      brush: headerBrush,
      bounds: Rect.fromLTWH(0, 0, pageSize.width, 100),
    );

    // Title
    page.graphics.drawString(
      'VEHICLE HEALTH REPORT',
      titleFont,
      brush: PdfSolidBrush(PdfColor(255, 195, 0)),
      bounds: Rect.fromLTWH(0, 30, pageSize.width, 40),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Divider
    page.graphics.drawLine(
      PdfPen(PdfColor(255, 195, 0)), 
      Offset(50, 90),
      Offset(pageSize.width - 50, 90),
    );

    double yPos = 110;

    // Summary Card
    final PdfSolidBrush summaryBrush = PdfSolidBrush(PdfColor(50, 50, 50));
    page.graphics.drawRectangle(
      brush: summaryBrush,
      bounds: Rect.fromLTWH(40, yPos, pageSize.width - 80, 120),
    );

    page.graphics.drawString(
      'DIAGNOSIS SUMMARY',
      subHeadingFont,
      brush: PdfSolidBrush(PdfColor(255, 195, 0)),
      bounds: Rect.fromLTWH(50, yPos + 15, pageSize.width - 100, 20),
    );

    // Summary items
    _drawStatusItem(page, 'Engine Status', engineStatusText, engineStatusColor, yPos + 45, pageSize.width);
    _drawStatusItem(page, 'Fuel Consumption', '${fuelConsumption.toStringAsFixed(1)}%', 
        fuelConsumption <= 30 ? PdfColor(0, 200, 0) : 
        fuelConsumption <= 70 ? PdfColor(255, 165, 0) : PdfColor(200, 0, 0), 
        yPos + 75, pageSize.width);
    _drawStatusItem(page, 'Mileage', '${mileage.toStringAsFixed(1)} MPG',
        mileage <= 80 ? PdfColor(200, 0, 0) : 
        mileage <= 160 ? PdfColor(255, 165, 0) : PdfColor(0, 200, 0),
        yPos + 105, pageSize.width);

    yPos += 150;

    // Detailed Analysis Section
    page.graphics.drawString(
      'DETAILED ANALYSIS',
      headingFont,
      brush: PdfSolidBrush(PdfColor(255, 195, 0)),
      bounds: Rect.fromLTWH(50, yPos, pageSize.width - 100, 30),
    );
    yPos += 40;

    // Engine Health Card
    _drawAnalysisCard(
      page: page,
      yPos: yPos,
      pageSize: pageSize,
      title: 'ENGINE HEALTH',
      status: engineStatusText,
      statusColor: engineStatusColor,
      description: isEngineHealthy 
          ? 'Your engine is operating within normal parameters. No immediate action required.'
          : 'Potential engine issues detected. Recommended actions:\n• Check engine oil level\n• Inspect spark plugs\n• Scan for error codes',
    );
    yPos += 130;

    // Fuel Consumption Card
    String fuelAdvice;
    if (fuelConsumption <= 30) {
      fuelAdvice = 'Excellent fuel efficiency. Maintain current maintenance schedule.';
    } else if (fuelConsumption <= 70) {
      fuelAdvice = 'Moderate fuel consumption. Recommendations:\n• Check air filter\n• Ensure proper tire inflation\n• Use recommended fuel grade';
    } else {
      fuelAdvice = 'High fuel consumption detected. Critical actions:\n• Check for fuel leaks\n• Inspect oxygen sensors\n• Consider engine diagnostic';
    }

    _drawAnalysisCard(
      page: page,
      yPos: yPos,
      pageSize: pageSize,
      title: 'FUEL CONSUMPTION',
      status: '${fuelConsumption.toStringAsFixed(1)}%',
      statusColor: fuelConsumption <= 30 ? PdfColor(0, 200, 0) : 
          fuelConsumption <= 70 ? PdfColor(255, 165, 0) : PdfColor(200, 0, 0),
      description: fuelAdvice,
    );
    yPos += 130;

    // Mileage Card
    String mileageAdvice;
    if (mileage <= 80) {
      mileageAdvice = 'Low mileage efficiency. Immediate actions:\n• Check engine performance\n• Inspect transmission\n• Review driving habits';
    } else if (mileage <= 160) {
      mileageAdvice = 'Average mileage efficiency. Recommendations:\n• Regular oil changes\n• Maintain proper tire pressure\n• Lighten vehicle load';
    } else {
      mileageAdvice = 'Excellent mileage efficiency. Your vehicle is performing optimally.';
    }

    _drawAnalysisCard(
      page: page,
      yPos: yPos,
      pageSize: pageSize,
      title: 'MILEAGE',
      status: '${mileage.toStringAsFixed(1)} MPG',
      statusColor: mileage <= 80 ? PdfColor(200, 0, 0) : 
          mileage <= 160 ? PdfColor(255, 165, 0) : PdfColor(0, 200, 0),
      description: mileageAdvice,
    );

    // Footer
    page.graphics.drawString(
      'Generated by Dr. Vehicle • ${DateFormat.yMMMMd().format(DateTime.now())}',
      smallFont,
      brush: PdfSolidBrush(PdfColor(150, 150, 150)),
      bounds: Rect.fromLTWH(0, pageSize.height - 30, pageSize.width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Vehicle_Health_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await document.save());
    document.dispose();

    OpenFile.open(file.path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF report generated successfully!')),
    );
  }

  void _drawStatusItem(PdfPage page, String label, String value, PdfColor color, double yPos, double pageWidth) {
    // Label
    page.graphics.drawString(
      label,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(60, yPos, 200, 20),
    );

    // Value background
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(color),
      bounds: Rect.fromLTWH(pageWidth - 160, yPos, 100, 20),
    );
    // Value text
    page.graphics.drawString(
      value,
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(pageWidth - 160, yPos, 100, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
  }

  void _drawAnalysisCard({
    required PdfPage page,
    required double yPos,
    required Size pageSize,
    required String title,
    required String status,
    required PdfColor statusColor,
    required String description,
  }) {
    // Card background
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(50, 50, 50)),
      bounds: Rect.fromLTWH(40, yPos, pageSize.width - 80, 120),
    );
    page.graphics.drawString(
      title,
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(PdfColor(255, 195, 0)),
      bounds: Rect.fromLTWH(50, yPos + 15, pageSize.width - 100, 20),
    );

    // Status pill
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(statusColor),
      bounds: Rect.fromLTWH(50, yPos + 45, 120, 25),
    );
    page.graphics.drawString(
      status,
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(50, yPos + 45, 120, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Description
    page.graphics.drawString(
      description,
      PdfStandardFont(PdfFontFamily.helvetica, 11),
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(180, yPos + 45, pageSize.width - 230, 70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engineHealth = _extractValue("Engine Health", predictionResult);
    final fuelConsumption = double.tryParse(
            _extractValue("Fuel Consumption", predictionResult)) ??
        0.0;
    final mileage =
        double.tryParse(_extractValue("Mileage", predictionResult)) ?? 0.0;

    // Determine health status for engine
    final isEngineHealthy = engineHealth.trim() == "1";
    final engineStatusText = isEngineHealthy ? "GOOD" : "NEEDS ATTENTION";
    final engineStatusColor = isEngineHealthy ? Colors.green : Colors.red;

    // Determine fuel consumption status
    String fuelStatus;
    Color fuelStatusColor;
    if (fuelConsumption <= 30) {
      fuelStatus = "EFFICIENT";
      fuelStatusColor = Colors.green;
    } else if (fuelConsumption <= 70) {
      fuelStatus = "AVERAGE";
      fuelStatusColor = Colors.orange;
    } else {
      fuelStatus = "INEFFICIENT";
      fuelStatusColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'DIAGNOSIS RESULTS',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Engine Health Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Icon(
                    isEngineHealthy ? Icons.check_circle : Icons.warning,
                    size: 40,
                    color: engineStatusColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENGINE STATUS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          engineStatusText,
                          style: TextStyle(
                            color: engineStatusColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fuel Consumption Gauge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
              ),
              child: Column(
                children: [
                  Text(
                    'FUEL CONSUMPTION',
                    style: TextStyle(
                      color: kYellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 0,
                          maximum: 100,
                          ranges: <GaugeRange>[
                            GaugeRange(
                              startValue: 0,
                              endValue: 30,
                              color: Colors.green,
                            ),
                            GaugeRange(
                              startValue: 30,
                              endValue: 70,
                              color: Colors.orange,
                            ),
                            GaugeRange(
                              startValue: 70,
                              endValue: 100,
                              color: Colors.red,
                            ),
                          ],
                          pointers: <GaugePointer>[
                            NeedlePointer(
                              value: fuelConsumption,
                              needleColor: kYellow,
                              needleStartWidth: 1,
                              needleEndWidth: 5,
                              knobStyle: KnobStyle(
                                knobRadius: 0.08,
                                color: kYellow,
                              ),
                            ),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              widget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${fuelConsumption.toStringAsFixed(1)}%",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    fuelStatus,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: fuelStatusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              angle: 90,
                              positionFactor: 0.6,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mileage Gauge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kDarkCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
              ),
              child: Column(
                children: [
                  Text(
                    'MILEAGE (MPG)',
                    style: TextStyle(
                      color: kYellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 0,
                          maximum: 240,
                          ranges: <GaugeRange>[
                            GaugeRange(
                              startValue: 0,
                              endValue: 80,
                              color: Colors.red,
                            ),
                            GaugeRange(
                              startValue: 80,
                              endValue: 160,
                              color: Colors.orange,
                            ),
                            GaugeRange(
                              startValue: 160,
                              endValue: 240,
                              color: Colors.green,
                            ),
                          ],
                          pointers: <GaugePointer>[
                            NeedlePointer(
                              value: mileage,
                              needleColor: kYellow,
                              needleStartWidth: 1,
                              needleEndWidth: 5,
                              knobStyle: KnobStyle(
                                knobRadius: 0.08,
                                color: kYellow,
                              ),
                            ),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              widget: Text(
                                "${mileage.toStringAsFixed(1)} MPG",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              angle: 90,
                              positionFactor: 0.6,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate PDF Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _generatePdf(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save to History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showSaveDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _extractValue(String label, String result) {
    final regex = RegExp("$label: ([^\\n]*)");
    final match = regex.firstMatch(result);
    return match?.group(1)?.trim() ?? "";
  }
}