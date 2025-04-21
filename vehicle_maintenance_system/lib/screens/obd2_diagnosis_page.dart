import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dr_vehicle/screens/prediction_page.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

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

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
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

      final response = await http.post(
        Uri.parse("https://kelum0602-vehicle-maintenance.hf.space/predict"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"data": [inputValues]}),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to get prediction: ${response.reasonPhrase}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
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

  Widget _buildInputField(String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controllers[key],
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: key.replaceAll("_", " ").toUpperCase(),
          labelStyle: const TextStyle(color: kYellow),
          filled: true,
          fillColor: kDarkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kYellow),
          ),
        ),
        validator: (val) => val == null || val.isEmpty ? "Required" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'OBD-II Diagnosis',
          style: TextStyle(
            color: kYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackground,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              for (var key in controllers.keys) _buildInputField(key),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : predictFromAPI,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'RUN DIAGNOSIS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}