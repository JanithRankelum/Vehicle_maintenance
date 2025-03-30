import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SendObdCommandPage extends StatefulWidget {
  const SendObdCommandPage({super.key});

  @override
  _SendObdCommandPageState createState() => _SendObdCommandPageState();
}

class _SendObdCommandPageState extends State<SendObdCommandPage> {
  BluetoothCharacteristic? obdCharacteristic;
  String obdResponse = "";

  // List of OBD-II commands to get vehicle data
  List<String> obdCommands = [
    "0105", // Coolant Temperature
    "0104", // Engine Load
    "010C", // Engine RPM
    "012F", // Fuel Tank Level
    "010D", // Vehicle Speed
    "011F", // Engine Run Time
    "010F", // Intake Air Temperature
    "010B", // Intake Manifold Pressure
  ];

  // Send a specific OBD-II command
  Future<void> sendObdCommand(String command) async {
    if (obdCharacteristic == null) {
      setState(() {
        obdResponse = "❌ No OBD-II characteristic available!";
      });
      return;
    }

    try {
      List<int> obdCommand = utf8.encode("$command\r"); // Append carriage return (\r)
      await obdCharacteristic!.write(obdCommand, withoutResponse: true);
      await Future.delayed(Duration(milliseconds: 200)); // Allow time for response

      // Read the response from the OBD-II system
      List<int> response = await obdCharacteristic!.read();
      String responseStr = utf8.decode(response);
      setState(() {
        obdResponse = "📊 OBD-II Response for command $command: $responseStr";
      });
    } catch (e) {
      setState(() {
        obdResponse = "❌ Failed to send OBD-II command: $e";
      });
    }
  }

  // Get all OBD-II features
  Future<void> getObdFeatures() async {
    for (String command in obdCommands) {
      await sendObdCommand(command);
      await Future.delayed(Duration(seconds: 1)); // Delay between requests to avoid flooding the OBD-II system
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send OBD-II Command"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: getObdFeatures,
              child: Text("Get Vehicle Features"),
            ),
            SizedBox(height: 20),
            Text(
              "OBD-II Response:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              obdResponse.isNotEmpty ? obdResponse : "No response yet.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
