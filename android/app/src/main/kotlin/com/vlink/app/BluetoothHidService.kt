package com.vlink.app

import android.annotation.SuppressLint
import android.bluetooth.*
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * V-LINK BluetoothHidService
 * Registers the phone as a Bluetooth HID device (keyboard + mouse).
 * Requires API 28+ (Android 9).
 *
 * Usage: Call startAdvertising() to make phone discoverable as HID device.
 * Host PC pairs with it like a normal Bluetooth keyboard.
 */
@RequiresApi(Build.VERSION_CODES.P)
@SuppressLint("MissingPermission")
class BluetoothHidService(private val context: Context) {

    private var bluetoothHidDevice: BluetoothHidDevice? = null
    private var hostDevice: BluetoothDevice? = null
    private var statusCallback: ((String) -> Unit)? = null

    // ── HID Descriptor ────────────────────────────────────────────────────────
    // Combined keyboard + mouse HID report descriptor
    private val hidDescriptor = byteArrayOf(
        // Keyboard
        0x05.toByte(), 0x01.toByte(), // Usage Page (Generic Desktop)
        0x09.toByte(), 0x06.toByte(), // Usage (Keyboard)
        0xA1.toByte(), 0x01.toByte(), // Collection (Application)
        0x85.toByte(), 0x01.toByte(), //   Report ID (1)
        0x05.toByte(), 0x07.toByte(), //   Usage Page (Key Codes)
        0x19.toByte(), 0xE0.toByte(), //   Usage Minimum (224)
        0x29.toByte(), 0xE7.toByte(), //   Usage Maximum (231)
        0x15.toByte(), 0x00.toByte(), //   Logical Minimum (0)
        0x25.toByte(), 0x01.toByte(), //   Logical Maximum (1)
        0x75.toByte(), 0x01.toByte(), //   Report Size (1)
        0x95.toByte(), 0x08.toByte(), //   Report Count (8)
        0x81.toByte(), 0x02.toByte(), //   Input (Data, Variable, Absolute) -- modifier keys
        0x95.toByte(), 0x01.toByte(), //   Report Count (1)
        0x75.toByte(), 0x08.toByte(), //   Report Size (8)
        0x81.toByte(), 0x01.toByte(), //   Input (Constant) -- reserved
        0x95.toByte(), 0x06.toByte(), //   Report Count (6)
        0x75.toByte(), 0x08.toByte(), //   Report Size (8)
        0x15.toByte(), 0x00.toByte(), //   Logical Minimum (0)
        0x25.toByte(), 0x65.toByte(), //   Logical Maximum (101)
        0x05.toByte(), 0x07.toByte(), //   Usage Page (Key Codes)
        0x19.toByte(), 0x00.toByte(), //   Usage Minimum (0)
        0x29.toByte(), 0x65.toByte(), //   Usage Maximum (101)
        0x81.toByte(), 0x00.toByte(), //   Input (Data, Array) -- keys
        0xC0.toByte(),                  // End Collection
        // Mouse
        0x05.toByte(), 0x01.toByte(), // Usage Page (Generic Desktop)
        0x09.toByte(), 0x02.toByte(), // Usage (Mouse)
        0xA1.toByte(), 0x01.toByte(), // Collection (Application)
        0x85.toByte(), 0x02.toByte(), //   Report ID (2)
        0x09.toByte(), 0x01.toByte(), //   Usage (Pointer)
        0xA1.toByte(), 0x00.toByte(), //   Collection (Physical)
        0x05.toByte(), 0x09.toByte(), //   Usage Page (Buttons)
        0x19.toByte(), 0x01.toByte(), //   Usage Minimum (1)
        0x29.toByte(), 0x03.toByte(), //   Usage Maximum (3)
        0x15.toByte(), 0x00.toByte(), //   Logical Minimum (0)
        0x25.toByte(), 0x01.toByte(), //   Logical Maximum (1)
        0x95.toByte(), 0x03.toByte(), //   Report Count (3)
        0x75.toByte(), 0x01.toByte(), //   Report Size (1)
        0x81.toByte(), 0x02.toByte(), //   Input (Data, Variable, Absolute)
        0x95.toByte(), 0x01.toByte(), //   Report Count (1)
        0x75.toByte(), 0x05.toByte(), //   Report Size (5)
        0x81.toByte(), 0x01.toByte(), //   Input (Constant) -- padding
        0x05.toByte(), 0x01.toByte(), //   Usage Page (Generic Desktop)
        0x09.toByte(), 0x30.toByte(), //   Usage (X)
        0x09.toByte(), 0x31.toByte(), //   Usage (Y)
        0x15.toByte(), 0x81.toByte(), //   Logical Minimum (-127)
        0x25.toByte(), 0x7F.toByte(), //   Logical Maximum (127)
        0x75.toByte(), 0x08.toByte(), //   Report Size (8)
        0x95.toByte(), 0x02.toByte(), //   Report Count (2)
        0x81.toByte(), 0x06.toByte(), //   Input (Data, Variable, Relative)
        0xC0.toByte(),                  //   End Collection
        0xC0.toByte()                   // End Collection
    )

    private val sdpRecord = BluetoothHidDevice.AppSdpSettings(
        "V-LINK HID",
        "V-LINK Tactical Controller",
        "VLINK",
        BluetoothHidDevice.SUBCLASS1_COMBO,
        hidDescriptor
    )

    private val qosSettings = BluetoothHidDevice.AppQosSettings(
        BluetoothHidDevice.AppQosSettings.SERVICE_BEST_EFFORT,
        800, 9, 0, 11250, BluetoothHidDevice.AppQosSettings.MAX
    )

    private val callback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            if (registered) {
                statusCallback?.invoke("advertising")
            } else {
                statusCallback?.invoke("stopped")
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    hostDevice = device
                    statusCallback?.invoke("connected")
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    hostDevice = null
                    statusCallback?.invoke("disconnected")
                }
            }
        }

        override fun onGetReport(device: BluetoothDevice?, type: Byte, id: Byte, bufferSize: Int) {
            bluetoothHidDevice?.reportError(device, BluetoothHidDevice.ERROR_RSP_UNSUPPORTED_REQ)
        }

        override fun onSetReport(device: BluetoothDevice?, type: Byte, id: Byte, data: ByteArray?) {}
        override fun onSetProtocol(device: BluetoothDevice?, protocol: Byte) {}
        override fun onInterruptData(device: BluetoothDevice?, reportId: Byte, data: ByteArray?) {}
    }

    fun startAdvertising(onStatus: (String) -> Unit) {
        statusCallback = onStatus
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter
        bluetoothAdapter.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                bluetoothHidDevice = proxy as? BluetoothHidDevice
                bluetoothHidDevice?.registerApp(sdpRecord, qosSettings, qosSettings,
                    context.mainExecutor, callback)
            }
            override fun onServiceDisconnected(profile: Int) {
                bluetoothHidDevice = null
                statusCallback?.invoke("service_disconnected")
            }
        }, BluetoothProfile.HID_DEVICE)
    }

    fun stopAdvertising() {
        bluetoothHidDevice?.unregisterApp()
    }

    // ── Send keyboard report ───────────────────────────────────────────────────
    // modifier: bit flags for Ctrl/Shift/Alt/GUI
    // keycodes: up to 6 simultaneous keys (HID usage codes)
    fun sendKeyReport(modifier: Byte, keycodes: ByteArray) {
        val host = hostDevice ?: return
        val report = ByteArray(8)
        report[0] = modifier
        report[1] = 0 // reserved
        keycodes.forEachIndexed { i, k -> if (i < 6) report[2 + i] = k }
        bluetoothHidDevice?.sendReport(host, 1, report)
    }

    fun sendKeyRelease() {
        sendKeyReport(0, ByteArray(6))
    }

    // ── Send mouse report ──────────────────────────────────────────────────────
    // buttons: bit 0=left, bit 1=right, bit 2=middle
    // dx, dy: relative movement -127..127
    fun sendMouseReport(buttons: Byte, dx: Int, dy: Int) {
        val host = hostDevice ?: return
        val report = ByteArray(3)
        report[0] = buttons
        report[1] = dx.coerceIn(-127, 127).toByte()
        report[2] = dy.coerceIn(-127, 127).toByte()
        bluetoothHidDevice?.sendReport(host, 2, report)
    }

    // ── Key string → HID scancode ─────────────────────────────────────────────
    companion object {
        val keyMap = mapOf(
            "A" to 0x04, "B" to 0x05, "C" to 0x06, "D" to 0x07,
            "E" to 0x08, "F" to 0x09, "G" to 0x0A, "H" to 0x0B,
            "I" to 0x0C, "J" to 0x0D, "K" to 0x0E, "L" to 0x0F,
            "M" to 0x10, "N" to 0x11, "O" to 0x12, "P" to 0x13,
            "Q" to 0x14, "R" to 0x15, "S" to 0x16, "T" to 0x17,
            "U" to 0x18, "V" to 0x19, "W" to 0x1A, "X" to 0x1B,
            "Y" to 0x1C, "Z" to 0x1D,
            "1" to 0x1E, "2" to 0x1F, "3" to 0x20, "4" to 0x21,
            "5" to 0x22, "6" to 0x23, "7" to 0x24, "8" to 0x25,
            "9" to 0x26, "0" to 0x27,
            "ENTER" to 0x28, "ESC" to 0x29, "BACKSPACE" to 0x2A,
            "TAB" to 0x2B, "SPACE" to 0x2C, "CAPS" to 0x39,
            "F1" to 0x3A, "F2" to 0x3B, "F3" to 0x3C, "F4" to 0x3D,
            "F5" to 0x3E, "F6" to 0x3F, "F7" to 0x40, "F8" to 0x41,
            "F9" to 0x42, "F10" to 0x43, "F11" to 0x44, "F12" to 0x45,
        )
        const val MOD_LCTRL  = 0x01
        const val MOD_LSHIFT = 0x02
        const val MOD_LALT   = 0x04
        const val MOD_LGUI   = 0x08
    }
}
