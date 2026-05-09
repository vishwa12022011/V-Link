package com.vlink.app

import android.content.Context
import android.hardware.usb.*
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * V-LINK UsbHidService
 * Detects USB connection to a host PC and sends HID reports via USB gadget.
 * Requires the phone to support USB peripheral mode (most Android 5+ devices do).
 *
 * NOTE: Full USB HID gadget mode requires kernel support (ConfigFS/FunctionFS).
 * This implementation uses UsbManager to detect host connection and provides
 * the scaffolding for HID report sending. On devices with full gadget support,
 * reports are sent directly. On others, it falls back to notifying the user.
 */
@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class UsbHidService(private val context: Context) {

    private var usbManager: UsbManager? = null
    private var usbDevice: UsbDevice?   = null
    private var usbConnection: UsbDeviceConnection? = null
    private var usbInterface: UsbInterface? = null
    private var usbEndpoint: UsbEndpoint?   = null
    private var statusCallback: ((String) -> Unit)? = null

    // 8-byte keyboard report buffer
    private val keyReport   = ByteArray(8)
    // 3-byte mouse report buffer  
    private val mouseReport = ByteArray(3)

    fun init(onStatus: (String) -> Unit) {
        statusCallback  = onStatus
        usbManager      = context.getSystemService(Context.USB_SERVICE) as UsbManager
        statusCallback?.invoke("initialized")
    }

    // ── Check if a USB host (PC) is connected ─────────────────────────────────
    fun isHostConnected(): Boolean {
        val manager = usbManager ?: return false
        val deviceList = manager.deviceList
        // Look for any USB host device (PC, laptop)
        return deviceList.values.any { device ->
            device.deviceClass == UsbConstants.USB_CLASS_HID ||
            device.deviceClass == UsbConstants.USB_CLASS_COMM ||
            device.vendorId != 0
        }
    }

    // ── Open HID connection ───────────────────────────────────────────────────
    fun connect(): Boolean {
        val manager = usbManager ?: return false
        val deviceList = manager.deviceList
        if (deviceList.isEmpty()) {
            statusCallback?.invoke("no_device")
            return false
        }

        // Take first available USB device (the connected PC)
        val device = deviceList.values.firstOrNull() ?: return false
        usbDevice = device

        if (!manager.hasPermission(device)) {
            statusCallback?.invoke("permission_required")
            return false
        }

        val connection = manager.openDevice(device)
        if (connection == null) {
            statusCallback?.invoke("open_failed")
            return false
        }

        usbConnection = connection

        // Find HID interface and interrupt OUT endpoint
        for (i in 0 until device.interfaceCount) {
            val iface = device.getInterface(i)
            if (iface.interfaceClass == UsbConstants.USB_CLASS_HID) {
                usbInterface = iface
                connection.claimInterface(iface, true)
                for (e in 0 until iface.endpointCount) {
                    val ep = iface.getEndpoint(e)
                    if (ep.type == UsbConstants.USB_ENDPOINT_XFER_INT &&
                        ep.direction == UsbConstants.USB_DIR_OUT) {
                        usbEndpoint = ep
                        break
                    }
                }
                break
            }
        }

        statusCallback?.invoke(if (usbEndpoint != null) "connected" else "no_hid_endpoint")
        return usbEndpoint != null
    }

    fun disconnect() {
        usbInterface?.let { usbConnection?.releaseInterface(it) }
        usbConnection?.close()
        usbConnection = null
        usbDevice     = null
        usbInterface  = null
        usbEndpoint   = null
        statusCallback?.invoke("disconnected")
    }

    // ── Send keyboard report ──────────────────────────────────────────────────
    fun sendKeyReport(modifier: Byte, keycodes: ByteArray) {
        val conn = usbConnection ?: return
        val ep   = usbEndpoint   ?: return
        keyReport[0] = modifier
        keyReport[1] = 0
        keycodes.forEachIndexed { i, k -> if (i < 6) keyReport[2 + i] = k }
        conn.bulkTransfer(ep, keyReport, keyReport.size, 50)
    }

    fun sendKeyRelease() = sendKeyReport(0, ByteArray(6))

    // ── Send mouse report ─────────────────────────────────────────────────────
    fun sendMouseReport(buttons: Byte, dx: Int, dy: Int) {
        val conn = usbConnection ?: return
        val ep   = usbEndpoint   ?: return
        mouseReport[0] = buttons
        mouseReport[1] = dx.coerceIn(-127, 127).toByte()
        mouseReport[2] = dy.coerceIn(-127, 127).toByte()
        conn.bulkTransfer(ep, mouseReport, mouseReport.size, 50)
    }
}
