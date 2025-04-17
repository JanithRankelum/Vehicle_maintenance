import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

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
    final engineStatusText = isEngineHealthy ? "Good" : "Bad";
    final engineStatusColor = isEngineHealthy ? Colors.green : Colors.red;

    // Determine fuel consumption status
    String fuelStatus;
    if (fuelConsumption <= 30) {
      fuelStatus = "Good";
    } else if (fuelConsumption <= 70) {
      fuelStatus = "Intermediate";
    } else {
      fuelStatus = "Bad";
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Diagnosis Result")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Engine Health
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.engineering, size: 40, color: engineStatusColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Engine Health: $engineStatusText",
                      style: TextStyle(
                          fontSize: 20, color: engineStatusColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fuel Consumption Gauge
            Column(
              children: [
                const Text(
                  "Fuel Consumption",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 100,
                      pointers: <GaugePointer>[
                        NeedlePointer(value: fuelConsumption),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${fuelConsumption.toStringAsFixed(1)}%",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Status: $fuelStatus",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: fuelStatus == "Good"
                                      ? Colors.green
                                      : fuelStatus == "Intermediate"
                                          ? Colors.orange
                                          : Colors.red,
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
              ],
            ),
            const SizedBox(height: 24),

            // Mileage Gauge
            Column(
              children: [
                const Text(
                  "Mileage (MPG)",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 240,
                      pointers: <GaugePointer>[
                        NeedlePointer(value: mileage),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Text(
                            "${mileage.toStringAsFixed(1)} MPG",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          angle: 90,
                          positionFactor: 0.6,
                        ),
                      ],
                    ),
                  ],
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
