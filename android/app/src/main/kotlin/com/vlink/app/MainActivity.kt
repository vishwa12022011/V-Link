package com.vlink.app

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.vlink.app/hid"

    private lateinit var btHidService:  BluetoothHidService
    private lateinit var usbHidService: UsbHidService

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Init native services
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            btHidService = BluetoothHidService(this)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            usbHidService = UsbHidService(this)
            usbHidService.init { status ->
                runOnUiThread {
                    flutterEngine.dartExecutor.binaryMessenger.let { messenger ->
                        MethodChannel(messenger, CHANNEL)
                            .invokeMethod("onUsbHidStatus", status)
                    }
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Bluetooth HID ──────────────────────────────────────
                    "startBluetoothHid" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            btHidService.startAdvertising { status ->
                                runOnUiThread {
                                    MethodChannel(
                                        flutterEngine.dartExecutor.binaryMessenger, CHANNEL
                                    ).invokeMethod("onBtHidStatus", status)
                                }
                            }
                            result.success(null)
                        } else {
                            result.error("UNSUPPORTED",
                                "Bluetooth HID requires Android 9+", null)
                        }
                    }

                    "stopBluetoothHid" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            btHidService.stopAdvertising()
                        }
                        result.success(null)
                    }

                    // ── USB HID ────────────────────────────────────────────
                    "checkUsbConnected" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            result.success(usbHidService.isHostConnected())
                        } else {
                            result.success(false)
                        }
                    }

                    "startUsbHid" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            val ok = usbHidService.connect()
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

                    // ── Send key (routes to active HID channel) ────────────
                    "sendKey" -> {
                        val key     = call.argument<String>("key")     ?: ""
                        val pressed = call.argument<Boolean>("pressed") ?: true
                        _sendKey(key, pressed)
                        result.success(null)
                    }

                    // ── Send mouse ─────────────────────────────────────────
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

    // ── Key routing ────────────────────────────────────────────────────────────
    private fun _sendKey(key: String, pressed: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            ::btHidService.isInitialized) {
            val parts    = key.split("+")
            var modifier = 0
            val codes    = mutableListOf<Byte>()
            for (part in parts) {
                when (part.uppercase()) {
                    "L-CTRL",  "R-CTRL"  -> modifier = modifier or BluetoothHidService.MOD_LCTRL
                    "L-SHIFT", "R-SHIFT" -> modifier = modifier or BluetoothHidService.MOD_LSHIFT
                    "L-ALT",   "R-ALT"   -> modifier = modifier or BluetoothHidService.MOD_LALT
                    else -> {
                        val code = BluetoothHidService.keyMap[part.uppercase()]
                        if (code != null) codes.add(code.toByte())
                    }
                }
            }
            if (pressed) {
                btHidService.sendKeyReport(modifier.toByte(), codes.toByteArray())
            } else {
                btHidService.sendKeyRelease()
            }
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP &&
            ::usbHidService.isInitialized) {
            val code = BluetoothHidService.keyMap[key.uppercase()]
            if (code != null) {
                if (pressed) usbHidService.sendKeyReport(0, byteArrayOf(code.toByte()))
                else         usbHidService.sendKeyRelease()
            }
        }
    }

    private fun _sendMouse(dx: Int, dy: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            ::btHidService.isInitialized) {
            btHidService.sendMouseReport(0, dx, dy)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP &&
            ::usbHidService.isInitialized) {
            usbHidService.sendMouseReport(0, dx, dy)
        }
    }
}
