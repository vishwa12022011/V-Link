package com.vlink.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.vlink.app/hid"

    private lateinit var btHidService: BluetoothHidService
    private lateinit var usbHidService: UsbHidService
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Init native services
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            btHidService = BluetoothHidService(this)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            usbHidService = UsbHidService(this)
            usbHidService.init(
                onStatus = { status -> runOnUiThread { channel.invokeMethod("onUsbHidStatus", status) } },
                onHost = { hostName -> runOnUiThread { channel.invokeMethod("onUsbHostDetected", hostName) } }
            )
        }

        // Register USB broadcast receiver
        val filter = IntentFilter()
        filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        registerReceiver(usbReceiver, filter)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                // ── Bluetooth HID ──────────────────────────────────────
                "startBluetoothHid" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        btHidService.startAdvertising { status ->
                            runOnUiThread { channel.invokeMethod("onBtHidStatus", status) }
                        }
                        result.success(null)
                    } else {
                        result.error("UNSUPPORTED", "Bluetooth HID requires Android 9+", null)
                    }
                }
                "stopBluetoothHid" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        btHidService.stopAdvertising()
                    }
                    result.success(null)
                }

                // ── USB HID ────────────────────────────────────────────
                "checkUsbPrerequisites" -> {
                    checkUsbPrerequisites()
                    result.success(null)
                }
                "detectUsbHost" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        usbHidService.detectHost()
                    }
                    result.success(null)
                }
                "startUsbHid" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        val hostName = call.argument<String>("hostName") ?: ""
                        val ok = usbHidService.connect(hostName)
                        if (ok) result.success(null)
                        else result.error("USB_FAILED", "USB HID connection failed", null)
                    } else {
                        result.error("UNSUPPORTED", "USB HID requires Android 5+", null)
                    }
                }
                "stopUsbHid" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        usbHidService.disconnect()
                    }
                    result.success(null)
                }

                // ── Send Methods ───────────────────────────────────────
                "sendKey" -> {
                    val key = call.argument<String>("key") ?: ""
                    val pressed = call.argument<Boolean>("pressed") ?: true
                    _sendKey(key, pressed)
                    result.success(null)
                }
                "sendMouse" -> {
                    val dx = call.argument<Int>("dx") ?: 0
                    val dy = call.argument<Int>("dy") ?: 0
                    _sendMouse(dx, dy)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(usbReceiver)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            btHidService.stopAdvertising()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            usbHidService.disconnect()
        }
    }

    // ── USB Prerequisite Checks ──────────────────────────────────────────────
    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            checkUsbPrerequisites()
        }
    }

    private fun checkUsbPrerequisites() {
        val usbConnected = Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && usbHidService.isUsbConnected()
        val adbEnabled = Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
        val args = mapOf("usbConnected" to usbConnected, "usbDebuggingEnabled" to adbEnabled)
        runOnUiThread { channel.invokeMethod("onUsbPrerequisitesChanged", args) }
    }

    // ── Key/Mouse Routing ──────────────────────────────────────────────────
    private fun _sendKey(key: String, pressed: Boolean) {
        if (usbHidService.connect("")) { // Check if USB is the active channel
             usbHidService.sendKey(key, pressed)
             return
        }
        // Fallback to Bluetooth if available
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && ::btHidService.isInitialized) {
            val parts = key.split("+")
            var modifier = 0
            val codes = mutableListOf<Byte>()
            for (part in parts) {
                when (part.uppercase()) {
                    "L-CTRL", "R-CTRL" -> modifier = modifier or BluetoothHidService.MOD_LCTRL
                    "L-SHIFT", "R-SHIFT" -> modifier = modifier or BluetoothHidService.MOD_LSHIFT
                    "L-ALT", "R-ALT" -> modifier = modifier or BluetoothHidService.MOD_LALT
                    else -> {
                        val code = BluetoothHidService.keyMap[part.uppercase()]
                        if (code != null) codes.add(code.toByte())
                    }
                }
            }
            if (pressed) btHidService.sendKeyReport(modifier.toByte(), codes.toByteArray())
            else btHidService.sendKeyRelease()
        }
    }

    private fun _sendMouse(dx: Int, dy: Int) {
        if (usbHidService.connect("")) { // Check if USB is the active channel
            usbHidService.sendMouse(dx, dy)
            return
        }
        // Fallback to Bluetooth
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && ::btHidService.isInitialized) {
            btHidService.sendMouseReport(0, dx, dy)
        }
    }
}
