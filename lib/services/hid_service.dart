import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'wifi_service.dart';
import '../models/app_models.dart';

class HidService extends ChangeNotifier {
  static const _channel = MethodChannel('com.vlink.app/hid');

  // Dependencies
  WifiService? _wifiService;
  ConnModel?   _connModel;

  // State
  bool _btHidActive  = false;
  bool _usbHidActive = false;
  String? _btHidStatus;
  String? _usbHidStatus;
  String? _usbHostName;
  bool _usbConnected = false;
  bool _usbDebuggingEnabled = false;

  // Getters
  bool   get btHidActive   => _btHidActive;
  bool   get usbHidActive  => _usbHidActive;
  String get btHidStatus   => _btHidStatus  ?? 'Not started';
  String get usbHidStatus  => _usbHidStatus ?? 'Not connected';
  String? get usbHostName  => _usbHostName;
  bool get usbConnected => _usbConnected;
  bool get usbDebuggingEnabled => _usbDebuggingEnabled;

  HidService() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  void attach(WifiService wifi, ConnModel conn) {
    _wifiService = wifi;
    _connModel   = conn;
  }

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onBtHidStatus':
        _btHidStatus  = call.arguments as String?;
        _btHidActive  = _btHidStatus == 'connected';
        notifyListeners();
        break;
      case 'onUsbHidStatus':
        _usbHidStatus = call.arguments as String?;
        _usbHidActive = _usbHidStatus == 'connected';
        if (!_usbHidActive) _usbHostName = null;
        notifyListeners();
        break;
      case 'onUsbHostDetected':
        _usbHostName = call.arguments as String?;
        notifyListeners();
        break;
      case 'onUsbPrerequisitesChanged':
        final args = call.arguments as Map<dynamic, dynamic>?;
        _usbConnected = args?['usbConnected'] ?? false;
        _usbDebuggingEnabled = args?['usbDebuggingEnabled'] ?? false;
        notifyListeners();
        break;
    }
  }

  // ── Bluetooth HID ──────────────────────────────────────────────────────────
  Future<void> startBluetoothHid() async {
    try {
      await _channel.invokeMethod('startBluetoothHid');
      _btHidStatus = 'advertising';
      notifyListeners();
    } on PlatformException catch (e) {
      _btHidStatus = 'Error: ${e.message}';
      notifyListeners();
    }
  }

  Future<void> stopBluetoothHid() async {
    try {
      await _channel.invokeMethod('stopBluetoothHid');
      _btHidActive = false;
      _btHidStatus = 'stopped';
      notifyListeners();
    } catch (_) {}
  }

  // ── USB HID ────────────────────────────────────────────────────────────────
  Future<void> checkUsbPrerequisites() async {
    try {
      await _channel.invokeMethod('checkUsbPrerequisites');
    } catch (_) {}
  }

  Future<void> detectUsbHost() async {
    try {
      await _channel.invokeMethod('detectUsbHost');
    } on PlatformException catch (e) {
      _usbHostName = null;
      _usbHidStatus = 'Error: ${e.message}';
      notifyListeners();
    }
  }

  Future<void> startUsbHid() async {
    try {
      await _channel.invokeMethod('startUsbHid', {'hostName': _usbHostName});
    } on PlatformException catch (e) {
      _usbHidStatus = 'Error: ${e.message}';
      notifyListeners();
    }
  }

  Future<void> stopUsbHid() async {
    try {
      await _channel.invokeMethod('stopUsbHid');
    } catch (_) {}
  }

  // ── Unified Input Sending ──────────────────────────────────────────────────
  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (_connModel?.mode == Transport.wifi) {
      await _wifiService?.sendKey(key, pressed: pressed);
      return;
    }

    if (!_btHidActive && !_usbHidActive) return;
    try {
      await _channel.invokeMethod('sendKey', {
        'key':     key,
        'pressed': pressed,
      });
    } catch (_) {}
  }

  Future<void> sendMouse(int dx, int dy, {String? lmb, String? rmb}) async {
    if (_connModel?.mode == Transport.wifi) {
      await _wifiService?.sendMouse(dx, dy, lmb: lmb, rmb: rmb);
      return;
    }

    if (!_btHidActive && !_usbHidActive) return;
    try {
      await _channel.invokeMethod('sendMouse', {'dx': dx, 'dy': dy});
    } catch (_) {}
  }
}
