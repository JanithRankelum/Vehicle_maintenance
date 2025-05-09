import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

const kYellow = Color(0xFFFFC300);
const kDarkCard = Color(0xFF1C1C1E);
const kBackground = Colors.black;

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  static BluetoothDevice? connectedDevice;
  static dynamic obdCharacteristic; // <--- Added line

  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  List<BluetoothDevice> devices = [];
  bool isScanning = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  Map<String, bool> connectingDevices = {};

  BluetoothDevice? get connectedDevice => BluetoothScanPage.connectedDevice;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    if (connectedDevice != null) {
      _monitorConnection();
    }
  }

  Future<void> _initBluetooth() async {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        if (connectedDevice != null) {
          _monitorConnection();
        }
      } else {
        _clearConnection();
        setState(() {
          isScanning = false;
          devices.clear();
        });
      }
    });

    await _checkAndRequestPermissions();
  }

  void _monitorConnection() {
    connectedDevice?.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _clearConnection();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Device disconnected"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _clearConnection() {
    if (BluetoothScanPage.connectedDevice != null) {
      BluetoothScanPage.connectedDevice = null;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (await Permission.bluetooth.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted) {
      return true;
    }
    return false;
  }

  void scanForDevices() async {
    if (!await FlutterBluePlus.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bluetooth not supported on this device"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!await FlutterBluePlus.isOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enable Bluetooth"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isScanning = true;
      devices.clear();
    });

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );

    _scanResultsSubscription?.cancel();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devices.contains(result.device)) {
          setState(() {
            devices.add(result.device);
          });
        }
      }
    }, onError: (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Scan error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    });

    Future.delayed(const Duration(seconds: 15), () {
      FlutterBluePlus.stopScan();
      setState(() => isScanning = false);
      _scanResultsSubscription?.cancel();
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    String deviceId = device.id.toString();
    setState(() => connectingDevices[deviceId] = true);

    try {
      await device.connect(autoConnect: false);

      BluetoothScanPage.connectedDevice = device;
      _monitorConnection();

      setState(() {
        connectingDevices[deviceId] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connected to OBD2 device!"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => connectingDevices[deviceId] = false);
    }
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
        _clearConnection();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Device disconnected"),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Disconnection failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
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
            if (connectedDevice != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: kDarkCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Icon(
                    Icons.bluetooth_connected,
                    color: kYellow,
                  ),
                  title: Text(
                    connectedDevice!.name.isNotEmpty ? connectedDevice!.name : "Unknown Device",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Connected",
                    style: const TextStyle(color: Colors.green),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: disconnectDevice,
                    child: const Text("DISCONNECT"),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: devices.isEmpty
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
                      itemCount: devices.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        String deviceId = device.id.toString();
                        bool isConnecting = connectingDevices[deviceId] ?? false;

                        return Container(
                          decoration: BoxDecoration(
                            color: kDarkCard,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: const Icon(
                              Icons.bluetooth,
                              color: Colors.white70,
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
                            trailing: ElevatedButton(
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
