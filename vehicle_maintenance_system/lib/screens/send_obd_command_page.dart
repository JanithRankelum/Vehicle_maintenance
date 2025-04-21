import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class SendObdCommandPage extends StatefulWidget {
  final BluetoothCharacteristic obdCharacteristic;

  const SendObdCommandPage({super.key, required this.obdCharacteristic});

  @override
  State<SendObdCommandPage> createState() => _SendObdCommandPageState();
}

class _SendObdCommandPageState extends State<SendObdCommandPage> {
  Timer? pollingTimer;
  double time = 0;
  bool isPolling = false;

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

  final Map<String, List<FlSpot>> dataPoints = {};
  final Map<String, double> currentValues = {};

  @override
  void initState() {
    super.initState();
    // Initialize data points
    for (var label in commands.values) {
      dataPoints[label] = [];
      currentValues[label] = 0;
    }
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  void togglePolling() {
    if (isPolling) {
      stopPolling();
    } else {
      startRealtimePolling();
    }
  }

  void startRealtimePolling() {
    setState(() => isPolling = true);
    pollingTimer?.cancel();
    pollingTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      for (var command in commands.keys) {
        await sendObdCommand(command);
      }
      setState(() => time += 1);
    });
  }

  void stopPolling() {
    setState(() => isPolling = false);
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
          currentValues[label] = value;
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

  Widget buildChart(String label, List<FlSpot> spots, Color color) {
    final unit = getUnit(label);
    final currentValue = currentValues[label]?.toStringAsFixed(1) ?? '0';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kDarkCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kYellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$currentValue $unit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _getInterval(label),
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: AxisTitles(),
                    topTitles: AxisTitles(),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: color,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    )
                  ],
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getInterval(label),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                  ),
                  minY: 0,
                  lineTouchData: LineTouchData(enabled: false),
                ),
              ),
            ),
          ],
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
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'OBD-II Data',
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
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPolling ? Colors.red[800] : kYellow,
                foregroundColor: isPolling ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: togglePolling,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isPolling ? Icons.stop : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(
                    isPolling ? 'STOP POLLING' : 'START POLLING',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: commands.values.map((label) {
                  final color = Colors.primaries[label.hashCode % Colors.primaries.length];
                  return buildChart(label, dataPoints[label]!, color);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}