import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class PredictionPage extends StatelessWidget {
  final String predictionResult;

  const PredictionPage({super.key, required this.predictionResult});

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