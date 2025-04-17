import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class SendObdCommandPage extends StatefulWidget {
  final BluetoothCharacteristic obdCharacteristic;

  const SendObdCommandPage({super.key, required this.obdCharacteristic});

  @override
  State<SendObdCommandPage> createState() => _SendObdCommandPageState();
}

class _SendObdCommandPageState extends State<SendObdCommandPage> {
  Timer? pollingTimer;
  double time = 0;

  final Map<String, String> commands = {
    "010C": "Engine RPM",
    "010D": "Speed",
    "0105": "Coolant Temp",
    "012F": "Fuel Level",
    "0104": "Engine Load",
    "010F": "Intake Temp",
    "010B": "Manifold Pressure",
    "011F": "Engine Run Time",
  };

  final Map<String, List<FlSpot>> dataPoints = {
    "Engine RPM": [],
    "Speed": [],
    "Coolant Temp": [],
    "Fuel Level": [],
    "Engine Load": [],
    "Intake Temp": [],
    "Manifold Pressure": [],
    "Engine Run Time": [],
  };

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  void startRealtimePolling() {
    pollingTimer?.cancel();
    pollingTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      for (var command in commands.keys) {
        await sendObdCommand(command);
      }
      setState(() => time += 1);
    });
  }

  void stopPolling() {
    pollingTimer?.cancel();
  }

  Future<void> sendObdCommand(String command) async {
    try {
      final characteristic = widget.obdCharacteristic;
      List<int> obdCommand = utf8.encode("$command\r");
      await characteristic.write(obdCommand, withoutResponse: true);
      await Future.delayed(Duration(milliseconds: 200));

      List<int> response = await characteristic.read();
      String responseStr = utf8.decode(response).replaceAll('\r', '').trim();

      double? value = parseOBDResponse(command, responseStr);
      if (value != null) {
        final label = commands[command]!;
        setState(() {
          dataPoints[label]!.add(FlSpot(time, value));
          if (dataPoints[label]!.length > 30) {
            dataPoints[label]!.removeAt(0); // keep recent 30
          }
        });
      }
    } catch (e) {
      print("Error sending $command: $e");
    }
  }

  double? parseOBDResponse(String command, String response) {
    final parts = response.replaceAll('\n', '').split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != '41') return null;

    try {
      switch (command) {
        case "010C": // RPM
          if (parts.length >= 4) {
            int A = int.parse(parts[2], radix: 16);
            int B = int.parse(parts[3], radix: 16);
            return ((256 * A + B) / 4).toDouble();
          }
          break;
        case "010D": // Speed
        case "010B": // Manifold Pressure
          return int.parse(parts[2], radix: 16).toDouble();
        case "0105": // Coolant Temp
        case "010F": // Intake Air Temp
          return int.parse(parts[2], radix: 16) - 40.0;
        case "012F": // Fuel Level
        case "0104": // Engine Load
          return (int.parse(parts[2], radix: 16) * 100) / 255.0;
        case "011F": // Engine Run Time
          if (parts.length >= 4) {
            int A = int.parse(parts[2], radix: 16);
            int B = int.parse(parts[3], radix: 16);
            return (256 * A + B).toDouble(); // in seconds
          }
      }
    } catch (_) {}
    return null;
  }

  Widget buildChart(List<FlSpot> spots, String label, Color color, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text('$label ($unit)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 200, child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 5),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: _getInterval(label)),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: color,
                      dotData: FlDotData(show: false),
                    )
                  ],
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  String getUnit(String label) {
    switch (label) {
      case "Engine RPM": return "RPM";
      case "Speed": return "km/h";
      case "Coolant Temp":
      case "Intake Temp": return "°C";
      case "Fuel Level":
      case "Engine Load": return "%";
      case "Manifold Pressure": return "kPa";
      case "Engine Run Time": return "sec";
      default: return "";
    }
  }

  double _getInterval(String label) {
    switch (label) {
      case "Engine RPM": return 1000;
      case "Speed": return 20;
      case "Fuel Level":
      case "Engine Load": return 20;
      case "Coolant Temp":
      case "Intake Temp": return 10;
      case "Manifold Pressure": return 10;
      case "Engine Run Time": return 60;
      default: return 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Real-Time OBD-II Monitoring")),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: startRealtimePolling,
                icon: Icon(Icons.play_arrow),
                label: Text("Start"),
              ),
              ElevatedButton.icon(
                onPressed: stopPolling,
                icon: Icon(Icons.pause),
                label: Text("Stop"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: dataPoints.entries.map((entry) {
                  final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
                  return buildChart(entry.value, entry.key, color, getUnit(entry.key));
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
