import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

class WifiService extends ChangeNotifier {
  static const _port = 4242;
  static const _broadcast = '255.255.255.255';
  static const _pingMsg = 'VLINK_CLIENT_PING';
  static const _pongMsg = 'VLINK_SERVER_ACK';

  String ip = '192.168.4.1';
  bool discovering = false;

  RawDatagramSocket? _sock;
  RawDatagramSocket? _discSock;
  ConnModel? _conn;
  Timer? _discTimer;

  List<String> discoveredHosts = [];

  void attach(ConnModel c) => _conn = c;
  bool get connected => _sock != null;

  void setIp(String v) {
    ip = v;
    notifyListeners();
  }

  Future<void> startDiscovery() async {
    if (discovering) return;
    discovering = true;
    discoveredHosts.clear();
    notifyListeners();
    _conn?.log('WiFi: Discovery started');

    try {
      _discSock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0,
          reuseAddress: true);
      _discSock!.broadcastEnabled = true;

      _discSock!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _discSock!.receive();
          if (dg == null) return;
          final msg = utf8.decode(dg.data);
          if (msg.startsWith(_pongMsg)) {
            final host = dg.address.address;
            if (!discoveredHosts.contains(host)) {
              discoveredHosts.add(host);
              _conn?.log('WiFi: Found device at $host');
              notifyListeners();
            }
          }
        }
      });

      _discTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _discSock?.send(
            utf8.encode(_pingMsg), InternetAddress(_broadcast), _port);
      });
      _discSock!
          .send(utf8.encode(_pingMsg), InternetAddress(_broadcast), _port);

      Future.delayed(const Duration(seconds: 15), () {
        if (discovering) stopDiscovery();
      });
    } catch (e) {
      _conn?.log('WiFi discovery error: $e');
      discovering = false;
      notifyListeners();
    }
  }

  Future<void> stopDiscovery() async {
    discovering = false;
    _discTimer?.cancel();
    _discSock?.close();
    _discSock = null;
    _conn?.log('WiFi: Discovery stopped');
    notifyListeners();
  }

  Future<void> connect() async {
    if (discovering) await stopDiscovery();
    try {
      _sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _conn?.setStatus(ConnStatus.connected, device: ip, mode: Transport.wifi);
      _conn?.log('WiFi: UDP socket bound to $ip:$_port');
      notifyListeners();
    } catch (e) {
      _conn?.log('WiFi connect error: $e');
    }
  }

  Future<void> disconnect() async {
    _sock?.close();
    _sock = null;
    _conn?.setStatus(ConnStatus.disconnected);
    _conn?.log('WiFi: Disconnected');
    notifyListeners();
  }

  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (_sock == null) return;
    final packet = {
      "type": "keyboard",
      "key": key,
      "state": pressed ? "down" : "up"
    };
    try {
      _sock!.send(utf8.encode(jsonEncode(packet)), InternetAddress(ip), _port);
    } catch (_) {}
  }

  Future<void> sendMouse(int dx, int dy, {String? lmb, String? rmb}) async {
    if (_sock == null) return;
    final packet = {
      "type": "mouse",
      "dx": dx,
      "dy": dy,
      if (lmb != null) 'LMB': lmb,
      if (rmb != null) 'RMB': rmb,
    };
    try {
      _sock!.send(utf8.encode(jsonEncode(packet)), InternetAddress(ip), _port);
    } catch (_) {}
  }
}
