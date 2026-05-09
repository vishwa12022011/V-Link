import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flutter-side bridge to native Android BT HID and USB HID services.
/// Communicates with BluetoothHidService.kt and UsbHidService.kt
/// via a MethodChannel.
class HidService extends ChangeNotifier {
  static const _channel = MethodChannel('com.vlink.app/hid');

  bool _btHidActive  = false;
  bool _usbHidActive = false;
  String? _btHidStatus;
  String? _usbHidStatus;

  bool   get btHidActive   => _btHidActive;
  bool   get usbHidActive  => _usbHidActive;
  String get btHidStatus   => _btHidStatus  ?? 'Not started';
  String get usbHidStatus  => _usbHidStatus ?? 'Not connected';

  HidService() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  // ── Incoming calls from native ─────────────────────────────────────────────
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
  Future<bool> checkUsbConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsbConnected');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> startUsbHid() async {
    try {
      await _channel.invokeMethod('startUsbHid');
      _usbHidStatus = 'connected';
      _usbHidActive = true;
      notifyListeners();
    } on PlatformException catch (e) {
      _usbHidStatus = 'Error: ${e.message}';
      notifyListeners();
    }
  }

  Future<void> stopUsbHid() async {
    try {
      await _channel.invokeMethod('stopUsbHid');
      _usbHidActive = false;
      _usbHidStatus = 'stopped';
      notifyListeners();
    } catch (_) {}
  }

  // ── Send key via active HID channel ───────────────────────────────────────
  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (!_btHidActive && !_usbHidActive) return;
    try {
      await _channel.invokeMethod('sendKey', {
        'key':     key,
        'pressed': pressed,
      });
    } catch (_) {}
  }

  // ── Send mouse via active HID channel ─────────────────────────────────────
  Future<void> sendMouse(int dx, int dy) async {
    if (!_btHidActive && !_usbHidActive) return;
    try {
      await _channel.invokeMethod('sendMouse', {'dx': dx, 'dy': dy});
    } catch (_) {}
  }
}
