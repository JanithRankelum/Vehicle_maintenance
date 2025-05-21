import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SendObdCommandPage extends StatefulWidget {
  final BluetoothCharacteristic? obdCharacteristic;

  const SendObdCommandPage({super.key, this.obdCharacteristic});

  @override
  _SendObdCommandPageState createState() => _SendObdCommandPageState();
}

class _SendObdCommandPageState extends State<SendObdCommandPage> {
  // Vehicle metrics
  double _rpm = 0.0;
  double _throttle = 0.0;
  double _speed = 0.0;
  double _boost = 0.0;
  double _coolantTemp = 0.0;
  Timer? _dataTimer;
  bool _isConnected = false;

  // OBD2 PIDs we'll monitor
  final Map<String, String> _obdPids = {
    'rpm': '010C',
    'speed': '010D',
    'throttle': '0111',
    'boost': '010B', // MAP sensor
    'coolant': '0105',
  };

  @override
  void initState() {
    super.initState();
    _initializeObd();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeObd() async {
    if (widget.obdCharacteristic == null) return;

    try {
      // Initialize ELM327 adapter
      await _sendCommand('ATZ');
      await _sendCommand('ATE0'); // Echo off
      await _sendCommand('ATL0'); // Linefeeds off
      await _sendCommand('ATS0'); // Spaces off

      setState(() => _isConnected = true);
      
      // Start polling data every second
      _dataTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
        _pollAllData();
      });
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  Future<void> _pollAllData() async {
    if (!_isConnected) return;

    try {
      // Get all metrics in parallel
      await Future.wait([
        _getRpm(),
        _getSpeed(),
        _getThrottle(),
        _getBoost(),
        _getCoolantTemp(),
      ]);
    } catch (e) {
      print('Polling error: $e');
    }
  }

  Future<void> _getRpm() async {
    final response = await _sendCommand(_obdPids['rpm']!);
    final rpm = _parseRpmResponse(response);
    if (rpm != null) {
      setState(() => _rpm = rpm);
    }
  }

  Future<void> _getSpeed() async {
    final response = await _sendCommand(_obdPids['speed']!);
    final speed = _parseSpeedResponse(response);
    if (speed != null) {
      setState(() => _speed = speed);
    }
  }

  Future<void> _getThrottle() async {
    final response = await _sendCommand(_obdPids['throttle']!);
    final throttle = _parseThrottleResponse(response);
    if (throttle != null) {
      setState(() => _throttle = throttle);
    }
  }

  Future<void> _getBoost() async {
    final response = await _sendCommand(_obdPids['boost']!);
    final boost = _parseBoostResponse(response);
    if (boost != null) {
      setState(() => _boost = boost);
    }
  }

  Future<void> _getCoolantTemp() async {
    final response = await _sendCommand(_obdPids['coolant']!);
    final temp = _parseCoolantResponse(response);
    if (temp != null) {
      setState(() => _coolantTemp = temp);
    }
  }

  Future<String> _sendCommand(String command) async {
    final cmdWithCR = utf8.encode('$command\r');
    await widget.obdCharacteristic!.write(cmdWithCR, withoutResponse: false);
    await Future.delayed(Duration(milliseconds: 300));
    final response = await widget.obdCharacteristic!.read();
    return utf8.decode(response).trim();
  }

  // Parsing methods for each metric
  double? _parseRpmResponse(String response) {
    try {
      final hexValue = response.split(' ')[2]; // Example: "41 0C 1A F8"
      return int.parse(hexValue, radix: 16) / 4.0; // RPM formula
    } catch (e) {
      print('Error parsing RPM: $e');
      return null;
    }
  }

  double? _parseSpeedResponse(String response) {
    try {
      final hexValue = response.split(' ')[2];
      return int.parse(hexValue, radix: 16).toDouble(); // km/h
    } catch (e) {
      print('Error parsing speed: $e');
      return null;
    }
  }

  double? _parseThrottleResponse(String response) {
    try {
      final hexValue = response.split(' ')[2];
      return (int.parse(hexValue, radix: 16) * 100 / 255); // Percentage
    } catch (e) {
      print('Error parsing throttle: $e');
      return null;
    }
  }

  double? _parseBoostResponse(String response) {
    try {
      final hexValue = response.split(' ')[2];
      return (int.parse(hexValue, radix: 16) / 10 - 1); // PSI
    } catch (e) {
      print('Error parsing boost: $e');
      return null;
    }
  }

  double? _parseCoolantResponse(String response) {
    try {
      final hexValue = response.split(' ')[2];
      return int.parse(hexValue, radix: 16) - 40; // Celsius
    } catch (e) {
      print('Error parsing coolant: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OBD2 Dashboard'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: _isConnected
          ? SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // RPM Gauge
                  _buildGauge(
                    title: 'REVS',
                    value: _rpm,
                    unit: 'x1000',
                    min: 0,
                    max: 8,
                    divisions: 8,
                    color: Colors.red,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Throttle Gauge
                  _buildGauge(
                    title: 'THROTTLE',
                    value: _throttle,
                    unit: '%',
                    min: 0,
                    max: 100,
                    divisions: 10,
                    color: Colors.green,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Speed Gauge
                  _buildGauge(
                    title: 'SPEED',
                    value: _speed,
                    unit: 'km/h',
                    min: 0,
                    max: 160,
                    divisions: 8,
                    color: Colors.blue,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Boost Gauge
                  _buildGauge(
                    title: 'BOOST',
                    value: _boost,
                    unit: 'PSI',
                    min: -20,
                    max: 20,
                    divisions: 10,
                    color: Colors.orange,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Coolant Temp Gauge
                  _buildGauge(
                    title: 'COOLANT',
                    value: _coolantTemp,
                    unit: '°C',
                    min: -40,
                    max: 120,
                    divisions: 8,
                    color: _coolantTemp > 100 ? Colors.red : Colors.blue,
                  ),
                ],
              ),
            )
          : Center(
              child: Text(
                'Connecting to OBD2...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
    );
  }

  Widget _buildGauge({
    required String title,
    required double value,
    required String unit,
    required double min,
    required double max,
    required int divisions,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: (value - min) / (max - min),
            backgroundColor: Colors.grey[800],
            color: color,
            minHeight: 20,
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min $unit',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '$max $unit',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}