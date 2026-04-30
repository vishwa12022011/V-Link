import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

class WifiService extends ChangeNotifier {
  static const _port = 4242;
  String ip = '192.168.4.1';
  RawDatagramSocket? _sock;
  ConnModel? _conn;
  bool get connected => _sock != null;

  void attach(ConnModel c) => _conn = c;
  void setIp(String v)     { ip = v; notifyListeners(); }

  Future<void> connect() async {
    try {
      _sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _conn?.setStatus(ConnStatus.connected, device: ip);
      _conn?.log('WIFI: UDP bound → $ip:$_port');
      notifyListeners();
    } catch (e) {
      _conn?.log('WIFI_ERR: $e');
    }
  }

  Future<void> disconnect() async {
    _sock?.close(); _sock = null;
    _conn?.setStatus(ConnStatus.disconnected);
    _conn?.log('WIFI: Disconnected');
    notifyListeners();
  }

  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (_sock == null) return;
    try {
      _sock!.send(
        utf8.encode(jsonEncode({'k': key, 's': pressed ? 1 : 0})),
        InternetAddress(ip), _port,
      );
    } catch (_) {}
  }
}
