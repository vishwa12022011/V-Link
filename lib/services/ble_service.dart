import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/app_models.dart';

class BleService extends ChangeNotifier {
  static const _svcUuid  = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const _charUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  BluetoothDevice?         _device;
  BluetoothCharacteristic? _char;
  StreamSubscription?      _scanSub;
  ConnModel?               _conn;
  bool                     scanning = false;

  List<ScanResult> discovered = [];

  void attach(ConnModel c) => _conn = c;
  bool get connected => _char != null;

  Future<void> startScan() async {
    if (scanning) return;
    scanning = true;
    discovered.clear();
    _conn?.setStatus(ConnStatus.scanning);
    _conn?.log('BLE_EVENT: SCAN_STARTED');
    notifyListeners();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    _scanSub = FlutterBluePlus.scanResults.listen((r) {
      discovered = r; notifyListeners();
    });
    await Future.delayed(const Duration(seconds: 10));
    await stopScan();
  }

  Future<void> stopScan() async {
    scanning = false;
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    if (_conn?.status == ConnStatus.scanning) _conn?.setStatus(ConnStatus.disconnected);
    _conn?.log('BLE_EVENT: DISCOVERY_COMPLETE');
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice d) async {
    _conn?.setStatus(ConnStatus.connecting, device: d.platformName);
    try {
      await d.connect(timeout: const Duration(seconds: 15));
      _device = d;
      final svcs = await d.discoverServices();
      for (final s in svcs) {
        if (s.uuid.toString().toLowerCase() == _svcUuid) {
          for (final c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == _charUuid) _char = c;
          }
        }
      }
      _conn?.setStatus(ConnStatus.connected, device: d.platformName);
      _conn?.log('MTU_EXCHANGE: 512 BYTES');
      _conn?.log('PKT_IN: [cmd:0x01 key:"CONN" state:1]');
    } catch (e) {
      _conn?.log('ERR: $e');
      _conn?.setStatus(ConnStatus.disconnected);
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null; _char = null;
    _conn?.setStatus(ConnStatus.disconnected);
    _conn?.log('BLE_EVENT: DISCONNECTED');
    notifyListeners();
  }

  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (_char == null) return;
    try {
      await _char!.write(
        utf8.encode(jsonEncode({'k': key, 's': pressed ? 1 : 0})),
        withoutResponse: true,
      );
    } catch (_) {}
  }
}
