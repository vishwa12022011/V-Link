import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/app_models.dart';

class BleService extends ChangeNotifier {
  static const _svcUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const _charUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _char;
  StreamSubscription? _scanSub;
  ConnModel? _conn;

  bool scanning = false;
  List<ScanResult> discovered = [];

  void attach(ConnModel c) => _conn = c;
  bool get connected => _char != null;

  // ── Scan ──────────────────────────────────────────────────────────────────
  Future<void> startScan() async {
    if (scanning) return;
    scanning = true;
    discovered.clear();
    notifyListeners();

    _conn?.setStatus(ConnStatus.scanning);
    _conn?.log('BLE: Scan started');

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        // No withServices filter — show ALL devices
      );
    } catch (e) {
      _conn?.log('BLE scan error: $e');
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      discovered = results;
      notifyListeners();
    });

    // Auto-stop after 15 s
    Future.delayed(const Duration(seconds: 15), () {
      if (scanning) stopScan();
    });
  }

  Future<void> stopScan() async {
    scanning = false;
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
    if (_conn?.status == ConnStatus.scanning) {
      _conn?.setStatus(ConnStatus.disconnected);
    }
    _conn?.log('BLE: Scan stopped — ${discovered.length} device(s) found');
    notifyListeners();
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> connect(BluetoothDevice device) async {
    if (scanning) await stopScan();
    _conn?.setStatus(ConnStatus.connecting,
        device: device.platformName.isNotEmpty
            ? device.platformName
            : device.remoteId.str);
    _conn?.log('BLE: Connecting to ${device.platformName}…');

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _device = device;

      final svcs = await device.discoverServices();
      for (final s in svcs) {
        if (s.uuid.toString().toLowerCase() == _svcUuid) {
          for (final c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == _charUuid) {
              _char = c;
            }
          }
        }
      }

      if (_char != null) {
        _conn?.setStatus(ConnStatus.connected,
            device: device.platformName.isNotEmpty
                ? device.platformName
                : device.remoteId.str);
        _conn?.log('BLE: V-LINK service found — ready');
      } else {
        // Connected but no V-LINK service — still mark connected
        // (user may connect to any device; HID won't work but connection succeeds)
        _conn?.setStatus(ConnStatus.connected,
            device: device.platformName.isNotEmpty
                ? device.platformName
                : device.remoteId.str);
        _conn?.log(
            'BLE: Connected (V-LINK HID service not found on this device)');
      }
    } catch (e) {
      _conn?.log('BLE: Connection failed — $e');
      _conn?.setStatus(ConnStatus.disconnected);
    }
    notifyListeners();
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _char = null;
    _conn?.setStatus(ConnStatus.disconnected);
    _conn?.log('BLE: Disconnected');
    notifyListeners();
  }

  // ── Send key packet ───────────────────────────────────────────────────────
  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (_char == null) return;
    try {
      final payload = utf8.encode(jsonEncode({'k': key, 's': pressed ? 1 : 0}));
      await _char!.write(payload, withoutResponse: true);
    } catch (_) {}
  }

  // ── Send mouse delta ──────────────────────────────────────────────────────
  Future<void> sendMouse(int dx, int dy) async {
    if (_char == null) return;
    try {
      final payload =
          utf8.encode(jsonEncode({'t': 'mouse', 'dx': dx, 'dy': dy}));
      await _char!.write(payload, withoutResponse: true);
    } catch (_) {}
  }
}
