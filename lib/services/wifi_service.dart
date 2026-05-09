import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

class WifiService extends ChangeNotifier {
  static const _port      = 4242;
  static const _broadcast = '255.255.255.255';
  static const _pingMsg   = 'VLINK_DISCOVER';
  static const _pongMsg   = 'VLINK_HERE';

  String  ip           = '192.168.4.1';
  bool    discovering  = false;

  RawDatagramSocket? _sock;       // send/receive socket
  RawDatagramSocket? _discSock;   // discovery socket
  ConnModel?         _conn;
  Timer?             _discTimer;

  List<String> discoveredHosts = [];

  void attach(ConnModel c) => _conn = c;
  bool get connected => _sock != null;

  void setIp(String v) { ip = v; notifyListeners(); }

  // ── UDP Broadcast Discovery ───────────────────────────────────────────────
  Future<void> startDiscovery() async {
    if (discovering) return;
    discovering = true;
    discoveredHosts.clear();
    notifyListeners();
    _conn?.log('WiFi: Discovery started — broadcasting on :$_port');

    try {
      _discSock = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, 0,
          reuseAddress: true);
      _discSock!.broadcastEnabled = true;

      // Listen for VLINK_HERE responses
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

      // Send broadcast ping every 2 s for 15 s
      _discTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _discSock?.send(
          utf8.encode(_pingMsg),
          InternetAddress(_broadcast),
          _port,
        );
      });
      // Send immediately
      _discSock!.send(
          utf8.encode(_pingMsg), InternetAddress(_broadcast), _port);

      // Auto-stop after 15 s
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
    _conn?.log('WiFi: Discovery stopped — ${discoveredHosts.length} host(s) found');
    notifyListeners();
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> connect() async {
    if (discovering) await stopDiscovery();
    try {
      _sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _conn?.setStatus(ConnStatus.connected, device: ip);
      _conn?.log('WiFi: UDP socket bound → $ip:$_port');
      notifyListeners();
    } catch (e) {
      _conn?.log('WiFi connect error: $e');
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    _sock?.close();
    _sock = null;
    _conn?.setStatus(ConnStatus.disconnected);
    _conn?.log('WiFi: Disconnected');
    notifyListeners();
  }

  // ── Send key packet ───────────────────────────────────────────────────────
  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (_sock == null) return;
    try {
      _sock!.send(
        utf8.encode(jsonEncode({'k': key, 's': pressed ? 1 : 0})),
        InternetAddress(ip), _port,
      );
    } catch (_) {}
  }

  // ── Send mouse delta ──────────────────────────────────────────────────────
  Future<void> sendMouse(int dx, int dy) async {
    if (_sock == null) return;
    try {
      _sock!.send(
        utf8.encode(jsonEncode({'t': 'mouse', 'dx': dx, 'dy': dy})),
        InternetAddress(ip), _port,
      );
    } catch (_) {}
  }
}
