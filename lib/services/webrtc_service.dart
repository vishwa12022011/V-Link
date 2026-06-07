import 'package:flutter/foundation.dart';

/// WebRTC service — handles both HID DataChannel and video stream.
/// PC-side signaling server required (pc_server/server.js).
/// This is a state model + placeholder; actual WebRTC peer connection
/// will be wired in once flutter_webrtc is added to pubspec.
class WebRtcService extends ChangeNotifier {
  WebRtcState state = WebRtcState.idle;
  String? sessionUrl; // signaling server URL from QR scan
  String? sessionToken;
  String? errorMsg;

  bool get isConnected => state == WebRtcState.connected;
  bool get isConnecting => state == WebRtcState.connecting;

  // ── Connect from QR payload ────────────────────────────────────────────────
  /// QR code contains JSON: {"url": "ws://192.168.1.x:3000", "token": "abc123"}
  Future<void> connectFromQr(String qrPayload) async {
    try {
      // Parse QR
      final parts = _parseQr(qrPayload);
      sessionUrl = parts['url'];
      sessionToken = parts['token'];

      state = WebRtcState.connecting;
      notifyListeners();

      // TODO: implement actual WebRTC peer connection
      // Steps:
      //   1. Connect to signaling WebSocket at sessionUrl
      //   2. Send session token for room join
      //   3. Exchange SDP offer/answer
      //   4. Exchange ICE candidates
      //   5. Open DataChannel for HID events
      //   6. Receive video track from PC screen capture

      // Simulate connecting for now
      await Future.delayed(const Duration(milliseconds: 800));
      state = WebRtcState.connected;
      notifyListeners();
    } catch (e) {
      state = WebRtcState.error;
      errorMsg = e.toString();
      notifyListeners();
    }
  }

  // ── Manual connect ─────────────────────────────────────────────────────────
  Future<void> connectManual(String url, String token) async {
    sessionUrl = url;
    sessionToken = token;
    await connectFromQr('{"url":"$url","token":"$token"}');
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    state = WebRtcState.idle;
    sessionUrl = null;
    sessionToken = null;
    errorMsg = null;
    notifyListeners();
  }

  // ── Send HID key via DataChannel ──────────────────────────────────────────
  Future<void> sendKey(String key, {bool pressed = true}) async {
    if (!isConnected) return;
    // TODO: send via RTCDataChannel
    // dataChannel.send({'k': key, 's': pressed ? 1 : 0});
  }

  // ── Send mouse delta via DataChannel ─────────────────────────────────────
  Future<void> sendMouse(int dx, int dy) async {
    if (!isConnected) return;
    // TODO: send via RTCDataChannel
    // dataChannel.send({'t': 'mouse', 'dx': dx, 'dy': dy});
  }

  Map<String, String> _parseQr(String payload) {
    // Expected: {"url":"ws://x.x.x.x:3000","token":"abc123"}
    final url =
        RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(payload)?.group(1) ?? '';
    final token =
        RegExp(r'"token"\s*:\s*"([^"]+)"').firstMatch(payload)?.group(1) ?? '';
    if (url.isEmpty) throw Exception('Invalid QR code — no URL found');
    return {'url': url, 'token': token};
  }

  String get statusText {
    switch (state) {
      case WebRtcState.idle:
        return 'Not connected';
      case WebRtcState.connecting:
        return 'Connecting…';
      case WebRtcState.connected:
        return 'Connected via Wi-Fi (WebRTC)';
      case WebRtcState.error:
        return 'Error: ${errorMsg ?? "unknown"}';
    }
  }
}

enum WebRtcState { idle, connecting, connected, error }
