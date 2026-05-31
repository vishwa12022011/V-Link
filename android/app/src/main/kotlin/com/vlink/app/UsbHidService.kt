package com.vlink.app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbManager
import android.os.BatteryManager
import android.os.Build
import androidx.annotation.RequiresApi
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.Socket

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class UsbHidService(private val context: Context) {

    private var usbManager: UsbManager? = null
    private var statusCallback: ((String) -> Unit)? = null
    private var hostCallback: ((String) -> Unit)? = null
    private var adbSocket: Socket? = null
    private var adbWriter: PrintWriter? = null

    fun init(onStatus: (String) -> Unit, onHost: (String) -> Unit) {
        statusCallback  = onStatus
        hostCallback    = onHost
        usbManager      = context.getSystemService(Context.USB_SERVICE) as UsbManager
        statusCallback?.invoke("initialized")
    }

    // ── Prerequisite Checks ────────────────────────────────────────────────────
    fun isUsbConnected(): Boolean {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val plugged = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
        return plugged == BatteryManager.BATTERY_PLUGGED_USB || plugged == BatteryManager.BATTERY_PLUGGED_AC
    }

    // ── ADB Handshake ──────────────────────────────────────────────────────────
    fun detectHost() {
        Thread {
            try {
                val process = Runtime.getRuntime().exec("adb reverse tcp:8888 tcp:8888")
                process.waitFor()

                adbSocket = Socket("127.0.0.1", 8888)
                adbWriter = PrintWriter(adbSocket!!.getOutputStream(), true)
                val reader = BufferedReader(InputStreamReader(adbSocket!!.getInputStream()))

                adbWriter?.println("I am V-Link")
                val hostName = reader.readLine()

                if (hostName != null) {
                    hostCallback?.invoke(hostName)
                    statusCallback?.invoke("host_detected")
                } else {
                    statusCallback?.invoke("no_host_response")
                }
            } catch (e: Exception) {
                statusCallback?.invoke("adb_error: ${e.message}")
            }
        }.start()
    }

    fun connect(hostName: String): Boolean {
        if (adbSocket == null || adbSocket!!.isClosed) {
            statusCallback?.invoke("adb_not_ready")
            return false
        }
        try {
            adbWriter?.println("now i am gonnna act as a hid keyboard and mouse vroo")
            statusCallback?.invoke("connected")
            return true
        } catch (e: Exception) {
            statusCallback?.invoke("connection_failed: ${e.message}")
            return false
        }
    }

    fun disconnect() {
        try {
            adbWriter?.println("disconnect")
            adbSocket?.close()
        } catch (_: Exception) {}
        adbSocket = null
        adbWriter = null
        statusCallback?.invoke("disconnected")
    }

    private fun sendPacket(json: String) {
        if (adbSocket == null || adbSocket!!.isClosed || adbWriter == null) return
        Thread {
            try {
                adbWriter?.println(json)
            } catch (e: Exception) {
                disconnect()
            }
        }.start()
    }

    fun sendKey(key: String, pressed: Boolean) {
        val state = if (pressed) "down" else "up"
        val json = "{\"type\":\"keyboard\",\"key\":\"$key\",\"state\":\"$state\"}"
        sendPacket(json)
    }

    fun sendMouse(dx: Int, dy: Int) {
        val json = "{\"type\":\"mouse\",\"dx\":$dx,\"dy\":$dy}"
        sendPacket(json)
    }
}
