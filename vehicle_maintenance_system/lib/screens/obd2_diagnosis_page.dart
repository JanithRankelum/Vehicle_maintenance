import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dr_vehicle/screens/prediction_page.dart';

class Obd2DiagnosisPage extends StatefulWidget {
  final Map<String, dynamic>? scannedData;

  const Obd2DiagnosisPage({super.key, this.scannedData});

  @override
  State<Obd2DiagnosisPage> createState() => _Obd2DiagnosisPageState();
}

class _Obd2DiagnosisPageState extends State<Obd2DiagnosisPage> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> controllers = {
    "COOLANT_TEMPERATURE": TextEditingController(),
    "ENGINE_LOAD": TextEditingController(),
    "ENGINE_RPM": TextEditingController(),
    "FUEL_TANK": TextEditingController(),
    "VEHICLE_SPEED": TextEditingController(),
    "ENGINE_RUN_TIME": TextEditingController(),
    "INTAKE_AIR_TEMP": TextEditingController(),
    "INTAKE_MANIFOLD_PRESSURE": TextEditingController(),
  };

  String result = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form fields with real-time scanned data if available
    if (widget.scannedData != null) {
      widget.scannedData!.forEach((key, value) {
        if (controllers.containsKey(key)) {
          controllers[key]!.text = value.toString();
        }
      });
    }
  }

  Future<void> predictFromAPI() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Collect input values from the form
      List<double> inputValues = [
        double.tryParse(controllers["COOLANT_TEMPERATURE"]!.text) ?? 0.0,
        double.tryParse(controllers["ENGINE_LOAD"]!.text) ?? 0.0,
        double.tryParse(controllers["ENGINE_RPM"]!.text) ?? 0.0,
        double.tryParse(controllers["FUEL_TANK"]!.text) ?? 0.0,
        double.tryParse(controllers["VEHICLE_SPEED"]!.text) ?? 0.0,
        double.tryParse(controllers["ENGINE_RUN_TIME"]!.text) ?? 0.0,
        double.tryParse(controllers["INTAKE_AIR_TEMP"]!.text) ?? 0.0,
        double.tryParse(controllers["INTAKE_MANIFOLD_PRESSURE"]!.text) ?? 0.0,
      ];

      final url = Uri.parse(
          "https://kelum0602-vehicle-maintenance.hf.space/predict");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"data": [inputValues]}), // Gradio expects 2D array
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final predictions = decoded["data"][0];

        final resultText = '''
🔧 Engine Health: ${predictions["Engine Health"]}
⛽ Fuel Consumption: ${predictions["Fuel Consumption"].toStringAsFixed(2)}
🛣️ Mileage: ${predictions["Mileage"].toStringAsFixed(2)}
''';

if (context.mounted) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PredictionPage(predictionResult: resultText),
    ),
  );
}

      } else {
        print("Error: ${response.statusCode}");
        print("Body: ${response.body}");
        setState(() => result = "❌ Failed: ${response.reasonPhrase}");
      }
    } catch (e) {
      setState(() => result = "❌ Error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OBD-II Maintenance Diagnosis")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
          children: [
            for (var entry in controllers.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextFormField(
                  controller: entry.value,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: entry.key.replaceAll("_", " ").toUpperCase(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Required" : null,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : predictFromAPI,
              child: Text(isLoading ? "Predicting..." : "Diagnose Vehicle"),
            ),
          ],
        ),
      ),
    ));
  }
}
