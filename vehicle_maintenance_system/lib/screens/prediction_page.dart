import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class PredictionPage extends StatelessWidget {
  final String predictionResult;

  const PredictionPage({super.key, required this.predictionResult});

  Future<void> _saveToFirestore(BuildContext context) async {
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('predictions')
          .add({
        'engineHealth': engineHealth,
        'fuelConsumption': fuelConsumption,
        'mileage': mileage,
        'timestamp': FieldValue.serverTimestamp(),
        'fullResult': predictionResult,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prediction saved successfully!')),
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

    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a new page
    final PdfPage page = document.pages.add();

    // Get page client size
    final Size pageSize = page.getClientSize();

    // Draw title
    page.graphics.drawString(
      'Vehicle Diagnosis Report',
      PdfStandardFont(PdfFontFamily.helvetica, 24),
      bounds: Rect.fromLTWH(0, 0, pageSize.width, 50),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Draw engine status
    page.graphics.drawString(
      'Engine Status: $engineStatusText',
      PdfStandardFont(PdfFontFamily.helvetica, 18),
      bounds: Rect.fromLTWH(50, 60, pageSize.width - 100, 30),
    );

    // Draw fuel consumption
    page.graphics.drawString(
      'Fuel Consumption: ${fuelConsumption.toStringAsFixed(1)}%',
      PdfStandardFont(PdfFontFamily.helvetica, 18),
      bounds: Rect.fromLTWH(50, 100, pageSize.width - 100, 30),
    );

    // Draw mileage
    page.graphics.drawString(
      'Mileage: ${mileage.toStringAsFixed(1)} MPG',
      PdfStandardFont(PdfFontFamily.helvetica, 18),
      bounds: Rect.fromLTWH(50, 140, pageSize.width - 100, 30),
    );

    // Draw timestamp
    page.graphics.drawString(
      'Report generated on: ${DateTime.now().toString()}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(50, pageSize.height - 50, pageSize.width - 100, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    // Save the document
    final List<int> bytes = await document.save();

    // Dispose the document
    document.dispose();

    // Get external storage directory
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/vehicle_diagnosis_report.pdf');

    // Write the file
    await file.writeAsBytes(bytes, flush: true);

    // Open the file
    OpenFile.open('$path/vehicle_diagnosis_report.pdf');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF report generated successfully!')),
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
                    onPressed: () => _saveToFirestore(context),
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