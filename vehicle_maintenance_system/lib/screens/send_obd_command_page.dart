import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SendObdCommandPage extends StatefulWidget {
  final BluetoothCharacteristic? obdCharacteristic;

  const SendObdCommandPage({super.key, this.obdCharacteristic});

  @override
  _SendObdCommandPageState createState() => _SendObdCommandPageState();
}

class _SendObdCommandPageState extends State<SendObdCommandPage> {
  final TextEditingController _commandController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  bool _isInitialized = false;
  Timer? _dataTimer;

  @override
  void initState() {
    super.initState();
    _initializeObd();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _dataTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeObd() async {
    if (widget.obdCharacteristic == null) {
      setState(() {
        _response = 'Please connect to an OBD2 device.';
      });
      return;
    }

    try {
      // Init sequence for ELM327 devices
      List<String> initCommands = ['ATZ', 'ATE0', 'ATL0', 'ATS0'];

      for (String cmd in initCommands) {
        await _sendRawCommand(cmd);
        await Future.delayed(Duration(milliseconds: 500));
      }

      setState(() {
        _isInitialized = true;
        _response = 'OBD initialized. Requesting initial data...';
      });

      // Request engine RPM (010C) as an initial data point
      await _sendRawCommand('010C');

      // Start polling for data every 1 second
      _dataTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _sendRawCommand('010C');
      });
    } catch (e) {
      setState(() {
        _response = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _sendRawCommand(String command) async {
    final cmdWithCR = utf8.encode('$command\r');
    await widget.obdCharacteristic!.write(cmdWithCR, withoutResponse: false);
    await Future.delayed(Duration(milliseconds: 300));

    final response = await widget.obdCharacteristic!.read();
    final decodedResponse = utf8.decode(response);
    print('Response to $command: $decodedResponse');

    setState(() {
      _response = decodedResponse.trim();
    });
  }

  Future<void> _sendCommand() async {
    if (!_isInitialized || widget.obdCharacteristic == null) {
      setState(() {
        _response = 'OBD2 device not initialized.';
      });
      return;
    }

    final command = _commandController.text.trim();
    if (command.isEmpty) {
      setState(() {
        _response = 'Please enter a command.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final encodedCommand = utf8.encode('$command\r');
      await widget.obdCharacteristic!
          .write(encodedCommand, withoutResponse: false);
      await Future.delayed(
          Duration(milliseconds: 500)); // Wait for the device to respond
      final response = await widget.obdCharacteristic!.read();
      final decoded = utf8.decode(response);
      print('Command Response: $decoded');

      setState(() {
        _response = decoded.trim();
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send OBD Command'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.obdCharacteristic == null
            ? Center(child: Text('Please connect to an OBD2 device.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _commandController,
                    decoration: InputDecoration(
                        labelText: 'Enter OBD Command (e.g., 010C)'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendCommand,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Send'),
                  ),
                  SizedBox(height: 16),
                  Text('Response:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(_response, style: TextStyle(fontSize: 16)),
                ],
              ),
      ),
    );
  }
}
