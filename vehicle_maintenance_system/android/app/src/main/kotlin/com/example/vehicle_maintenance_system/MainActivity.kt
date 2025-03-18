package com.example.vehicle_maintenance_system

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.your_app/bluetooth"
    private lateinit var bluetoothAdapter: BluetoothAdapter

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pairDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        pairDevice(address, result)
                    } else {
                        result.error("INVALID_ADDRESS", "Device address is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pairDevice(address: String, result: MethodChannel.Result) {
        val device = bluetoothAdapter.getRemoteDevice(address)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        try {
            val pairingIntent = Intent(BluetoothDevice.ACTION_PAIRING_REQUEST)
            pairingIntent.putExtra(BluetoothDevice.EXTRA_DEVICE, device)
            pairingIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(pairingIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("PAIRING_FAILED", "Failed to initiate pairing", e.message)
        }
    }
}