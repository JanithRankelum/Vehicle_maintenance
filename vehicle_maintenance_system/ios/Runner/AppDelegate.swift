import Flutter
import UIKit
import FirebaseCore
import CoreBluetooth

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Register Flutter plugins
        GeneratedPluginRegistrant.register(with: self)

        // Set up the Bluetooth plugin
        setupBluetoothPlugin()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupBluetoothPlugin() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }

        let bluetoothChannel = FlutterMethodChannel(name: "com.example.your_app/bluetooth",
                                                   binaryMessenger: controller.binaryMessenger)
        let bluetoothPlugin = SwiftBluetoothPlugin()
        bluetoothChannel.setMethodCallHandler { (call, result) in
            bluetoothPlugin.handle(call, result: result)
        }
    }
}

// SwiftBluetoothPlugin implementation
public class SwiftBluetoothPlugin: NSObject, FlutterPlugin {
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    private var result: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.your_app/bluetooth", binaryMessenger: registrar.messenger())
        let instance = SwiftBluetoothPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result

        switch call.method {
        case "pairDevice":
            if let arguments = call.arguments as? [String: Any],
               let address = arguments["address"] as? String {
                pairDevice(address: address)
            } else {
                result(FlutterError(code: "INVALID_ADDRESS", message: "Device address is null", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func pairDevice(address: String) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        // Convert address to UUID (if needed) or use it directly
        // Note: iOS does not allow direct pairing like Android. You need to connect and then pair.
        // This is a simplified example.
        let uuid = UUID(uuidString: address)
        if let uuid = uuid {
            let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
            if let peripheral = peripherals.first {
                discoveredPeripheral = peripheral
                centralManager.connect(peripheral, options: nil)
            } else {
                result?(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
            }
        } else {
            result?(FlutterError(code: "INVALID_ADDRESS", message: "Invalid device address", details: nil))
        }
    }
}

extension SwiftBluetoothPlugin: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            result?(FlutterError(code: "BLUETOOTH_OFF", message: "Bluetooth is turned off", details: nil))
        case .unauthorized:
            result?(FlutterError(code: "UNAUTHORIZED", message: "Bluetooth access is unauthorized", details: nil))
        default:
            result?(FlutterError(code: "BLUETOOTH_ERROR", message: "Bluetooth is not available", details: nil))
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "unnamed device")")
        result?(true)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "unknown error")")
        result?(FlutterError(code: "CONNECTION_FAILED", message: "Failed to connect to device", details: error?.localizedDescription))
    }
}