import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});
  static BluetoothCharacteristic? obdCharacteristic;

  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? scanSubscription;
  BluetoothDevice? connectedDevice;
  Map<String, bool> connectingDevices = {};
  BluetoothCharacteristic? obdCharacteristic;

  @override
  void initState() {
    super.initState();
    enableBluetooth();
  }

  Future<void> enableBluetooth() async {
    if (!(await FlutterBluePlus.isOn)) {
      await FlutterBluePlus.turnOn();
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  void scanForDevices() async {
    if (!await FlutterBluePlus.isAvailable || !await FlutterBluePlus.isOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enable Bluetooth manually"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Permissions not granted"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    await FlutterBluePlus.stopScan();
    FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    scanSubscription?.cancel();
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() => scanResults = results);
    });

    Future.delayed(Duration(seconds: 10), () async {
      await FlutterBluePlus.stopScan();
      setState(() => isScanning = false);
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    String deviceId = device.id.toString();
    setState(() => connectingDevices[deviceId] = true);

    try {
      await device.connect(autoConnect: false);
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write && characteristic.properties.read) {
            obdCharacteristic = characteristic;
            BluetoothScanPage.obdCharacteristic = characteristic;
            await sendObdCommand("010C");
            
            setState(() {
              connectedDevice = device;
              connectingDevices[deviceId] = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Connected & OBD-II Ready!"),
                backgroundColor: Colors.green,
              ),
            );
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No OBD-II characteristic found"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => connectingDevices[deviceId] = false);
  }

  Future<void> sendObdCommand(String command) async {
    if (obdCharacteristic == null) return;

    try {
      List<int> obdCommand = utf8.encode("$command\r");
      await obdCharacteristic!.write(obdCommand, withoutResponse: true);
      await Future.delayed(Duration(milliseconds: 200));
      
      List<int> response = await obdCharacteristic!.read();
      String responseStr = utf8.decode(response);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OBD-II Response: $responseStr"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send OBD-II command: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        obdCharacteristic = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Device disconnected"),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'OBD-II Scanner',
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
                backgroundColor: kYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: scanForDevices,
              child: Text(
                isScanning ? "SCANNING..." : "SCAN FOR DEVICES",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: scanResults.isEmpty
                  ? Center(
                      child: Text(
                        isScanning ? "Scanning for devices..." : "No devices found",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: scanResults.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final device = scanResults[index].device;
                        String deviceId = device.id.toString();
                        bool isConnecting = connectingDevices[deviceId] ?? false;
                        bool isConnected = connectedDevice?.id == device.id;

                        return Container(
                          decoration: BoxDecoration(
                            color: kDarkCard,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: Icon(
                              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                              color: isConnected ? kYellow : Colors.white70,
                            ),
                            title: Text(
                              device.name.isNotEmpty ? device.name : "Unknown Device",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              device.id.toString(),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: isConnected
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[800],
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: disconnectDevice,
                                    child: const Text("DISCONNECT"),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kYellow,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: isConnecting ? null : () => connectToDevice(device),
                                    child: isConnecting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Text("CONNECT"),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}